# frozen_string_literal: true

require 'securerandom'

module WithAdvisoryLock
  module MySQLAdvisory
    extend ActiveSupport::Concern

    def try_advisory_lock(lock_keys, lock_name:, shared:, transaction:, timeout_seconds: nil, blocking: false)
      raise ArgumentError, 'shared locks are not supported on MySQL' if shared
      raise ArgumentError, 'transaction level locks are not supported on MySQL' if transaction

      # Note: blocking parameter is accepted for API compatibility but ignored for MySQL
      # MySQL's GET_LOCK already provides native timeout support, making the blocking
      # parameter redundant. MySQL doesn't have separate try/blocking functions like PostgreSQL.

      # MySQL/MariaDB GET_LOCK supports native timeout:
      # - timeout_seconds = nil: wait indefinitely
      # - timeout_seconds = 0: try once, no wait (0)
      # - timeout_seconds > 0: wait up to timeout_seconds
      #
      # Note: MySQL accepts -1 for infinite wait, but MariaDB does not.
      # Using a large value (1 year) for cross-compatibility.
      mysql_timeout = case timeout_seconds
                      when nil then 31_536_000 # 1 year in seconds
                      when 0 then 0
                      else timeout_seconds.to_i
                      end

      execute_successful?("GET_LOCK(#{quote(lock_keys.first)}, #{mysql_timeout})")
    end

    def release_advisory_lock(*args, **kwargs)
      # Handle both signatures - ActiveRecord's built-in and ours
      if args.length == 1 && kwargs.empty?
        # ActiveRecord's signature: release_advisory_lock(lock_id)
        # Called by Rails migrations with a single positional argument
        super
      else
        # Our signature: release_advisory_lock(lock_keys, lock_name:, **)
        lock_keys = args.first
        execute_successful?("RELEASE_LOCK(#{quote(lock_keys.first)})")
      end
    rescue ActiveRecord::StatementInvalid => e
      # If the connection is broken, the lock is automatically released by MySQL
      # No need to fail the release operation
      raise unless connection_lost_error?(e)
    end

    def lock_keys_for(lock_name)
      lock_str = "#{ENV.fetch(CoreAdvisory::LOCK_PREFIX_ENV, nil)}#{lock_name}"
      [lock_str]
    end

    def supports_database_timeout?
      true
    end

    # Non-blocking check via IS_USED_LOCK, no lock is acquired as a side effect
    def advisory_lock_exists_for?(lock_name, shared: false)
      raise ArgumentError, 'shared locks are not supported on MySQL' if shared

      lock_keys = lock_keys_for(lock_name)
      !query_value("SELECT IS_USED_LOCK(#{quote(lock_keys.first)})").nil?
    rescue ActiveRecord::StatementInvalid
      nil
    end

    private

    def connection_lost_error?(error)
      cause = error.cause
      return true if defined?(Mysql2::Error::ConnectionError) && cause.is_a?(Mysql2::Error::ConnectionError)
      return true if defined?(Trilogy::ConnectionError) && cause.is_a?(Trilogy::ConnectionError)

      error.message.match?(/Lost connection|MySQL server has gone away|Connection refused/i)
    end

    def execute_successful?(mysql_function)
      query_value("SELECT #{mysql_function}") == 1
    end
  end
end
