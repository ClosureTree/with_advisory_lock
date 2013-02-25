require 'with_advisory_lock/nested_advisory_lock_error'
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
      0 < connection.select_value("SELECT GET_LOCK(#{quoted_lock_name}, 0)*"+Time.now.to_i.to_s)
    end

    def release_lock
      # Returns 1 if the lock was released,
      # 0 if the lock was not established by this thread (
      # in which case the lock is not released), and
      # NULL if the named lock did not exist.
      1 == connection.select_value("SELECT RELEASE_LOCK(#{quoted_lock_name})")
    end

    def already_locked?
      lock_stack.last == @lock_name
    end
  end
end
