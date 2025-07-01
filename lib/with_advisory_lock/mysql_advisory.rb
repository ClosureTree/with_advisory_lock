# frozen_string_literal: true

require 'securerandom'

module WithAdvisoryLock
  module MySQLAdvisory
    extend ActiveSupport::Concern

    LOCK_PREFIX_ENV = 'WITH_ADVISORY_LOCK_PREFIX'

    def try_advisory_lock(lock_keys, lock_name:, shared:, transaction:, timeout_seconds: nil)
      raise ArgumentError, 'shared locks are not supported on MySQL' if shared
      raise ArgumentError, 'transaction level locks are not supported on MySQL' if transaction

      # MySQL GET_LOCK supports native timeout:
      # - timeout_seconds = nil: wait indefinitely (-1)
      # - timeout_seconds = 0: try once, no wait (0)  
      # - timeout_seconds > 0: wait up to timeout_seconds
      mysql_timeout = case timeout_seconds
                     when nil then -1
                     when 0 then 0
                     else timeout_seconds.to_i
                     end

      execute_successful?("GET_LOCK(#{quote(lock_keys.first)}, #{mysql_timeout})")
    end

    def release_advisory_lock(lock_keys, lock_name:, **)
      execute_successful?("RELEASE_LOCK(#{quote(lock_keys.first)})")
    rescue ActiveRecord::StatementInvalid => e
      # If the connection is broken, the lock is automatically released by MySQL
      # No need to fail the release operation
      connection_lost = case e.cause
                       when defined?(Mysql2::Error::ConnectionError) && Mysql2::Error::ConnectionError
                         true
                       when defined?(Trilogy::ConnectionError) && Trilogy::ConnectionError
                         true
                       else
                         e.message =~ /Lost connection|MySQL server has gone away|Connection refused/i
                       end
      
      return if connection_lost
      
      raise
    end

    def lock_keys_for(lock_name)
      lock_str = "#{ENV.fetch(LOCK_PREFIX_ENV, nil)}#{lock_name}"
      [lock_str]
    end

    def supports_database_timeout?
      true
    end

    private

    def execute_successful?(mysql_function)
      select_value("SELECT #{mysql_function}") == 1
    end

# (Removed the `unique_column_name` method as it is unused.)
  end
end
