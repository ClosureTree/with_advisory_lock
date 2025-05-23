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
        impl = impl_class.new(connection, lock_name, options)
        impl.with_advisory_lock_if_needed(&block)
      end

      def advisory_lock_exists?(lock_name)
        impl = impl_class.new(connection, lock_name, 0)
        impl.already_locked? || !impl.yield_with_lock.lock_was_acquired?
      end

      def current_advisory_lock
        lock_stack_key = WithAdvisoryLock::Base.lock_stack.first
        lock_stack_key && lock_stack_key[0]
      end

      def current_advisory_locks
        WithAdvisoryLock::Base.lock_stack.map(&:name)
      end

      private

      def impl_class
        adapter = WithAdvisoryLock::DatabaseAdapterSupport.new(connection)
        if adapter.postgresql?
          WithAdvisoryLock::PostgreSQL
        elsif adapter.mysql?
          WithAdvisoryLock::MySQL
        else
          raise ArgumentError, "Unsupported adapter: #{adapter.adapter_name}"
        end
      end
    end
  end
end
