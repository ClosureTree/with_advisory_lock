module WithAdvisoryLock
  class PostgreSQL < Base
    # See http://www.postgresql.org/docs/9.1/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS
    def try_lock
      execute_successful?('pg_try_advisory_lock')
    end

    def release_lock
      execute_successful?('pg_advisory_unlock')
    end

    def execute_successful?(pg_function)
      sql = "SELECT #{pg_function}(#{lock_keys.join(',')}) AS #{unique_column_name}"
      result = connection.select_value(sql)
      # MRI returns 't', jruby returns true. YAY!
      (result == 't' || result == true)
    end

    # PostgreSQL wants 2 32bit integers as the lock key.
    def lock_keys
      @lock_keys ||= begin
        [stable_hashcode(lock_name), ENV['WITH_ADVISORY_LOCK_PREFIX']].map do |ea|
          # pg advisory args must be 31 bit ints
          ea.to_i & 0x7fffffff
        end
      end
    end
  end
end

