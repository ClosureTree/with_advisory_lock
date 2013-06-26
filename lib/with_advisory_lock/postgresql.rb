
module WithAdvisoryLock
  class PostgreSQL < Base

    # See http://www.postgresql.org/docs/9.1/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS

    def try_lock
      # pg_try_advisory_lock will either obtain the lock immediately
      # and return true, or return false if the lock cannot be acquired immediately
      sql = "SELECT pg_try_advisory_lock(#{numeric_lock}), #{Time.now.to_f}"
      "t" == connection.select_value(sql).to_s
    end

    def release_lock
      sql = "SELECT pg_advisory_unlock(#{numeric_lock}), #{Time.now.to_f}"
      "t" == connection.select_value(sql).to_s
    end

    def numeric_lock
      @numeric_lock ||= stable_hashcode(lock_name)
    end
  end
end
