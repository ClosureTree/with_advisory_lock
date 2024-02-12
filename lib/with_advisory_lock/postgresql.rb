# frozen_string_literal: true

module WithAdvisoryLock
  class PostgreSQL < Base
    # See https://www.postgresql.org/docs/16/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS

    # MRI returns 't', jruby returns true. YAY!
    LOCK_RESULT_VALUES = ['t', true].freeze
    PG_ADVISORY_UNLOCK = 'pg_advisory_unlock'
    PG_TRY_ADVISORY = 'pg_try_advisory'
    ERROR_MESSAGE_REGEX = / ERROR: +current transaction is aborted,/

    def try_lock
      execute_successful?(advisory_try_lock_function(transaction))
    end

    def release_lock
      return if transaction

      execute_successful?(advisory_unlock_function)
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ ERROR_MESSAGE_REGEX

      begin
        connection.rollback_db_transaction
        execute_successful?(advisory_unlock_function)
      ensure
        connection.begin_db_transaction
      end
    end

    def advisory_try_lock_function(transaction_scope)
      [
        'pg_try_advisory',
        transaction_scope ? '_xact' : nil,
        '_lock',
        shared ? '_shared' : nil
      ].compact.join
    end

    def advisory_unlock_function
      [
        'pg_advisory_unlock',
        shared ? '_shared' : nil
      ].compact.join
    end

    def execute_successful?(pg_function)
      result = connection.select_value(prepare_sql(pg_function))
      LOCK_RESULT_VALUES.include?(result)
    end

    def prepare_sql(pg_function)
      comment = lock_name.to_s.gsub(%r{(/\*)|(\*/)}, '--')
      "SELECT #{pg_function}(#{lock_keys.join(',')}) AS #{unique_column_name} /* #{comment} */"
    end

    # PostgreSQL wants 2 32bit integers as the lock key.
    def lock_keys
      @lock_keys ||= [
        stable_hashcode(lock_name),
        ENV[LOCK_PREFIX_ENV]
      ].map { |ea| ea.to_i & 0x7fffffff }
    end
  end
end
