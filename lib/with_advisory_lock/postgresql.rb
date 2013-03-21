require 'zlib'

module WithAdvisoryLock
  class PostgreSQL < Base

    # See http://www.postgresql.org/docs/9.1/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS

    def try_lock
      # pg_try_advisory_lock will either obtain the lock immediately
      # and return true, or return false if the lock cannot be acquired immediately
      "t" == connection.select_value("SELECT pg_try_advisory_lock(#{numeric_lock})")
    end

    def release_lock
      "t" == connection.select_value("SELECT pg_advisory_unlock(#{numeric_lock})")
    end

    def numeric_lock
      @numeric_lock ||= begin
        if lock_name.is_a? Numeric
          lock_name.to_i
        else
          # Ruby MRI's String#hash is randomly seeded as of Ruby 1.9 so
          # make sure we use a deterministic hash.
          Zlib.crc32(lock_name.to_s)
        end
      end
    end
  end
end
