# frozen_string_literal: true

module WithAdvisoryLock
  module Concern
    extend ActiveSupport::Concern
    delegate :with_advisory_lock, :with_advisory_lock!, :advisory_lock_exists?, to: 'self.class'

    class_methods do
      def with_advisory_lock(lock_name, options = {}, &block)
        result = with_advisory_lock_result(lock_name, options, &block)
        result.lock_was_acquired? ? result.result : false
      end

      def with_advisory_lock!(lock_name, options = {}, &block)
        result = with_advisory_lock_result(lock_name, options, &block)
        raise WithAdvisoryLock::FailedToAcquireLock, lock_name unless result.lock_was_acquired?

        result.result
      end

      def with_advisory_lock_result(lock_name, options = {}, &block)
        with_connection do |conn|
          conn.with_advisory_lock_if_needed(lock_name, options, &block)
        end
      end

      def advisory_lock_exists?(lock_name)
        with_connection do |conn|
          lock_str = "#{ENV.fetch(CoreAdvisory::LOCK_PREFIX_ENV, nil)}#{lock_name}"
          lock_stack_item = LockStackItem.new(lock_str, false)

          if conn.advisory_lock_stack.include?(lock_stack_item)
            true
          else
            # For PostgreSQL, try non-blocking query first to avoid race conditions
            if conn.respond_to?(:advisory_lock_exists_for?)
              query_result = conn.advisory_lock_exists_for?(lock_name)
              return query_result unless query_result.nil?
            end

            # Fall back to the original implementation
            result = conn.with_advisory_lock_if_needed(lock_name, { timeout_seconds: 0 })
            !result.lock_was_acquired?
          end
        end
      end

      def current_advisory_lock
        with_connection do |conn|
          conn.advisory_lock_stack.first&.name
        end
      end

      def current_advisory_locks
        with_connection do |conn|
          conn.advisory_lock_stack.map(&:name)
        end
      end
    end
  end
end
