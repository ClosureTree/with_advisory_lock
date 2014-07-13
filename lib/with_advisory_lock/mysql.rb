module WithAdvisoryLock
  class MySQL < Base
    # See http://dev.mysql.com/doc/refman/5.0/en/miscellaneous-functions.html#function_get-lock
    def try_lock
      unless lock_stack.empty?
        raise NestedAdvisoryLockError.new(
          "MySQL doesn't support nested Advisory Locks",
          lock_stack.dup)
      end
      execute_successful?("GET_LOCK(#{quoted_lock_str}, 0)")
    end

    def release_lock
      execute_successful?("RELEASE_LOCK(#{quoted_lock_str})")
    end

    def execute_successful?(mysql_function)
      sql = "SELECT #{mysql_function} AS #{unique_column_name}"
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
