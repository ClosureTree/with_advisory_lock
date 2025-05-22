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
        connection.with_advisory_lock_if_needed(lock_name, options, &block)
      end

      def advisory_lock_exists?(lock_name)
        lock_str = "#{ENV.fetch(CoreAdvisory::LOCK_PREFIX_ENV, nil)}#{lock_name}"
        lock_stack_item = LockStackItem.new(lock_str, false)

        if connection.advisory_lock_stack.include?(lock_stack_item)
          true
        else
          # Try to acquire lock with zero timeout to test if it's held
          result = connection.with_advisory_lock_if_needed(lock_name, { timeout_seconds: 0 })
          !result.lock_was_acquired?
        end
      end

      def current_advisory_lock
        connection.advisory_lock_stack.first&.name
      end

      def current_advisory_locks
        connection.advisory_lock_stack.map(&:name)
      end
    end
  end
end
