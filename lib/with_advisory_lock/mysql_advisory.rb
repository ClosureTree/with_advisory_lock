# frozen_string_literal: true

require 'securerandom'

module WithAdvisoryLock
  module MySQLAdvisory
    extend ActiveSupport::Concern

    LOCK_PREFIX_ENV = 'WITH_ADVISORY_LOCK_PREFIX'

    def try_advisory_lock(lock_keys, lock_name:, shared:, transaction:)
      raise ArgumentError, 'shared locks are not supported on MySQL' if shared
      raise ArgumentError, 'transaction level locks are not supported on MySQL' if transaction

      execute_successful?("GET_LOCK(#{quote(lock_keys.first)}, 0)")
    end

    def release_advisory_lock(lock_keys, lock_name:, **)
      execute_successful?("RELEASE_LOCK(#{quote(lock_keys.first)})")
    end

    def lock_keys_for(lock_name)
      lock_str = "#{ENV.fetch(LOCK_PREFIX_ENV, nil)}#{lock_name}"
      [lock_str]
    end

    private

    def execute_successful?(mysql_function)
      select_value("SELECT #{mysql_function}") == 1
    end

# (Removed the `unique_column_name` method as it is unused.)
  end
end
