# frozen_string_literal: true

module WithAdvisoryLock
  class MySQL < Base
    # Caches nested lock support by MySQL reported version
    @@mysql_nl_cache       = {}
    @@mysql_nl_cache_mutex = Mutex.new
    # See https://dev.mysql.com/doc/refman/5.7/en/miscellaneous-functions.html#function_get-lock
    def try_lock
      raise ArgumentError, 'shared locks are not supported on MySQL' if shared
      raise ArgumentError, 'transaction level locks are not supported on MySQL' if transaction

      execute_successful?("GET_LOCK(#{quoted_lock_str}, 0)")
    end

    def release_lock
      execute_successful?("RELEASE_LOCK(#{quoted_lock_str})")
    end

    def execute_successful?(mysql_function)
      sql = "SELECT #{mysql_function} AS #{unique_column_name}"
      connection.select_value(sql).to_i.positive?
    end

    # MySQL wants a string as the lock key.
    def quoted_lock_str
      connection.quote(lock_str)
    end
  end
end
