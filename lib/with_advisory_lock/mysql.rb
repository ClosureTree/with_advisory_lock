module WithAdvisoryLock
  class MySQL < Base
    # See http://dev.mysql.com/doc/refman/5.0/en/miscellaneous-functions.html#function_get-lock
    def try_lock
      unless lock_stack.empty?
        raise NestedAdvisoryLockError.new(
          "MySQL doesn't support nested Advisory Locks",
          lock_stack.dup)
      end
      # Returns 1 if the lock was obtained successfully,
      # 0 if the attempt timed out (for example, because another client has
      # previously locked the name), or NULL if an error occurred
      # (such as running out of memory or the thread was killed with mysqladmin kill).
      sql = "SELECT GET_LOCK(#{quoted_lock_str}, 0) #{query_cache_buster}"
      connection.select_value(sql).to_i > 0
    end

    def release_lock
      # Returns > 0 if the lock was released,
      # 0 if the lock was not established by this thread
      # (in which case the lock is not released), and
      # NULL if the named lock did not exist.
      sql = "SELECT RELEASE_LOCK(#{quoted_lock_str}) #{query_cache_buster}"
      connection.select_value(sql).to_i > 0
    end

    # MySQL doesn't support nested locks:
    def already_locked?
      lock_stack.last == lock_str
    end

    # MySQL wants a string as the lock key.
    def quoted_lock_str
      connection.quote(lock_str)
    end
  end
end
