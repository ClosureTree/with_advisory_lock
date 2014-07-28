require 'active_support/concern'

module WithAdvisoryLock
  module Concern
    extend ActiveSupport::Concern
    delegate :with_advisory_lock, :advisory_lock_exists?, to: 'self.class'

    module ClassMethods
      def with_advisory_lock(lock_name, timeout_seconds=nil, &block)
        result = with_advisory_lock_result(lock_name, timeout_seconds, &block)
        result.lock_was_acquired? ? result.result : false
      end

      def with_advisory_lock_result(lock_name, timeout_seconds=nil, &block)
        impl = impl_class.new(connection, lock_name, timeout_seconds)
        impl.with_advisory_lock_if_needed(&block)
      end

      def advisory_lock_exists?(lock_name)
        impl = impl_class.new(connection, lock_name, 0)
        impl.already_locked? || !impl.yield_with_lock.lock_was_acquired?
      end

      def current_advisory_lock
        WithAdvisoryLock::Base.lock_stack.first
      end

      private

      def impl_class
        adapter = WithAdvisoryLock::DatabaseAdapterSupport.new(connection)
        if adapter.postgresql?
          WithAdvisoryLock::PostgreSQL
        elsif adapter.mysql?
          WithAdvisoryLock::MySQL
        else
          WithAdvisoryLock::Flock
        end
      end
    end
  end
end
