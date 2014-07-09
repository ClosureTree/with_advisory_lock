module WithAdvisoryLock
  class PostgreSQL < Base
    # See http://www.postgresql.org/docs/9.1/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS
    def try_lock
      # pg_try_advisory_lock will either obtain the lock immediately and return true
      # or return false if the lock cannot be acquired immediately
      sql = "SELECT pg_try_advisory_lock(#{lock_keys.join(',')}) #{query_cache_buster}"
      't' == connection.select_value(sql).to_s
    end

    def release_lock
      sql = "SELECT pg_advisory_unlock(#{lock_keys.join(',')}) #{query_cache_buster}"
      't' == connection.select_value(sql).to_s
    end

    # PostgreSQL wants 2 32bit integers as the lock key.
    def lock_keys
      @lock_key ||= [if lock_name.is_a? Numeric
        lock_name.to_i
      else
        # The least significant 31 bits (first arg cannot be a bigint)
        stable_hashcode(lock_name) & 0x7fffffff
      end, ENV['WITH_ADVISORY_LOCK_PREFIX'].to_i]
    end
  end
end

