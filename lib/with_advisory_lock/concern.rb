# Tried desperately to monkeypatch the polymorphic connection object,
# but rails autoloading is too clever by half. Pull requests are welcome.

require 'active_support/concern'
require 'with_advisory_lock/base'
require 'with_advisory_lock/database_adapter_support'
require 'with_advisory_lock/flock'
require 'with_advisory_lock/mysql'
require 'with_advisory_lock/postgresql'

module WithAdvisoryLock
  module Concern
    extend ActiveSupport::Concern

    def with_advisory_lock(lock_name, timeout_seconds=nil, &block)
      self.class.with_advisory_lock(lock_name, timeout_seconds, &block)
    end

    module ClassMethods
      def with_advisory_lock(lock_name, timeout_seconds=nil, &block)
        das = WithAdvisoryLock::DatabaseAdapterSupport.new(connection)
        impl_class = if das.postgresql?
          WithAdvisoryLock::PostgreSQL
        elsif das.mysql?
          WithAdvisoryLock::MySQL
        else
          WithAdvisoryLock::Flock
        end
        impl = impl_class.new(connection, lock_name, timeout_seconds)
        impl.with_advisory_lock_if_needed(&block)
      end
    end
  end
end
