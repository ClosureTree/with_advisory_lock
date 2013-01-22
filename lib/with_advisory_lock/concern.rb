# Tried desperately to monkeypatch the polymorphic connection object,
# but rails autoloading is too clever by half. Pull requests are welcome.

# Think of this module as a hipster, using "case" ironically.

require 'with_advisory_lock/base'
require 'with_advisory_lock/mysql'
require 'with_advisory_lock/postgresql'
require 'with_advisory_lock/flock'
require 'active_support/concern'

module WithAdvisoryLock
  module Concern
    extend ActiveSupport::Concern

    def with_advisory_lock(lock_name, timeout_seconds=nil, &block)
      self.class.with_advisory_lock(lock_name, timeout_seconds, &block)
    end

    module ClassMethods

      def with_advisory_lock(lock_name, timeout_seconds=nil, &block)
        lock_stack = Thread.current[:with_advisory_lock_stack] ||= []
        impl = case (connection.adapter_name.downcase)
          when "postgresql"
            WithAdvisoryLock::PostgreSQL
          when "mysql", "mysql2"
            unless lock_stack.empty?
              wal_log("with_advisory_lock: MySQL doesn't support nested advisory locks, and will now release lock '#{lock_stack.last}'")
            end
            WithAdvisoryLock::MySQL
          else
            WithAdvisoryLock::Flock
        end
        lock_stack.push(lock_name)
        impl.new(connection, lock_name, timeout_seconds).with_advisory_lock(&block)
      ensure
        lock_stack.pop
      end

      def wal_log(msg)
        if respond_to?(:logger) && logger
          logger.warn(msg)
        else
          $stderr.puts(msg)
        end
      end
      private :wal_log
    end
  end
end