# frozen_string_literal: true

require 'zlib'

module WithAdvisoryLock
  module CoreAdvisory
    extend ActiveSupport::Concern

    LOCK_PREFIX_ENV = 'WITH_ADVISORY_LOCK_PREFIX'

    # Thread-local lock stack management
    def advisory_lock_stack
      Thread.current[:with_advisory_lock_stack] ||= []
    end

    def with_advisory_lock_if_needed(lock_name, options = {}, &block)
      options = { timeout_seconds: options } unless options.respond_to?(:fetch)
      options.assert_valid_keys :timeout_seconds, :shared, :transaction, :disable_query_cache

      lock_str = "#{ENV.fetch(LOCK_PREFIX_ENV, nil)}#{lock_name}"
      lock_stack_item = LockStackItem.new(lock_str, options.fetch(:shared, false))

      if advisory_lock_stack.include?(lock_stack_item)
        # Already have this exact lock (same name and type), just yield
        return Result.new(lock_was_acquired: true, result: yield)
      end

      # Check if we have a lock with the same name but different type (for upgrade/downgrade)
      same_name_different_type = advisory_lock_stack.any? do |item|
        item.name == lock_str && item.shared != options.fetch(:shared, false)
      end
      if same_name_different_type && options.fetch(:transaction, false)
        # PostgreSQL doesn't support upgrading/downgrading transaction-level locks
        return Result.new(lock_was_acquired: false)
      end

      disable_query_cache = options.fetch(:disable_query_cache, false)

      if disable_query_cache
        uncached do
          advisory_lock_and_yield(lock_name, lock_str, lock_stack_item, options, &block)
        end
      else
        advisory_lock_and_yield(lock_name, lock_str, lock_stack_item, options, &block)
      end
    end

    private

    def advisory_lock_and_yield(lock_name, lock_str, lock_stack_item, options, &block)
      timeout_seconds = options.fetch(:timeout_seconds, nil)
      shared = options.fetch(:shared, false)
      transaction = options.fetch(:transaction, false)

      lock_keys = lock_keys_for(lock_name)

      if timeout_seconds&.zero?
        yield_with_lock(lock_keys, lock_name, lock_str, lock_stack_item, shared, transaction, &block)
      else
        yield_with_lock_and_timeout(lock_keys, lock_name, lock_str, lock_stack_item, shared, transaction,
                                    timeout_seconds, &block)
      end
    end

    def yield_with_lock_and_timeout(lock_keys, lock_name, lock_str, lock_stack_item, shared, transaction,
                                    timeout_seconds, &block)
      give_up_at = timeout_seconds ? Time.now + timeout_seconds : nil
      while give_up_at.nil? || Time.now < give_up_at
        r = yield_with_lock(lock_keys, lock_name, lock_str, lock_stack_item, shared, transaction, &block)
        return r if r.lock_was_acquired?

        # Randomizing sleep time may help reduce contention.
        sleep(rand(0.05..0.15))
      end
      Result.new(lock_was_acquired: false)
    end

    def yield_with_lock(lock_keys, lock_name, _lock_str, lock_stack_item, shared, transaction)
      if try_advisory_lock(lock_keys, lock_name: lock_name, shared: shared, transaction: transaction)
        begin
          advisory_lock_stack.push(lock_stack_item)
          result = block_given? ? yield : nil
          Result.new(lock_was_acquired: true, result: result)
        ensure
          advisory_lock_stack.pop
          release_advisory_lock(lock_keys, lock_name: lock_name, shared: shared, transaction: transaction)
        end
      else
        Result.new(lock_was_acquired: false)
      end
    end

    def stable_hashcode(input)
      if input.is_a? Numeric
        input.to_i
      else
        # Ruby MRI's String#hash is randomly seeded as of Ruby 1.9 so
        # make sure we use a deterministic hash.
        Zlib.crc32(input.to_s, 0)
      end
    end
  end
end
