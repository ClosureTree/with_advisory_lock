
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

    def numeric_lock(name=lock_name)
      stable_hashcode(name)
    end

    def advisory_lock_exists?(name)
      sql = "SELECT 't'::text FROM pg_locks WHERE objid = #{numeric_lock(name)} AND locktype = 'advisory'"
      "t" == connection.select_value(sql).to_s
    end

  end
end
