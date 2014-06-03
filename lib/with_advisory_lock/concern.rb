# Tried desperately to monkeypatch the polymorphic connection object,
# but rails autoloading is too clever by half. Pull requests are welcome.

require 'active_support/concern'

module WithAdvisoryLock
  module Concern
    extend ActiveSupport::Concern

    delegate :with_advisory_lock, :advisory_lock_exists?, to: :class

    module ClassMethods
      def with_advisory_lock(lock_name, timeout_seconds=nil, &block)
        impl = impl_class.new(connection, lock_name, timeout_seconds)
        impl.with_advisory_lock_if_needed(&block)
      end

      def advisory_lock_exists?(lock_name)
        impl = impl_class.new(connection, lock_name, nil)
        impl.advisory_lock_exists?(lock_name)
      end

      def current_advisory_lock
        WithAdvisoryLock::Base.lock_stack.first
      end

      private

      def impl_class
        case WithAdvisoryLock::DatabaseAdapterSupport.new(connection).adapter
        when :postgresql
          WithAdvisoryLock::PostgreSQL
        when :mysql
          WithAdvisoryLock::MySQL
        else #sqlite
          WithAdvisoryLock::Flock
        end
      end
    end
  end
end
