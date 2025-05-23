# frozen_string_literal: true

require 'securerandom'

module WithAdvisoryLock
  # Methods mixed into the MySQL connection adapter to provide advisory locking
  # support compatible with +WithAdvisoryLock::Base+.
  module MySQL
    extend ActiveSupport::Concern

    def try_advisory_lock(lock_keys, lock_name:, shared:, transaction:)
      raise ArgumentError, 'shared locks are not supported on MySQL' if shared
      raise ArgumentError, 'transaction level locks are not supported on MySQL' if transaction

      execute_successful?("GET_LOCK(#{quote(lock_keys.first)}, 0)")
    end

    def release_advisory_lock(lock_keys, lock_name:, **)
      execute_successful?("RELEASE_LOCK(#{quote(lock_keys.first)})")
    end

    private

    def execute_successful?(mysql_function)
      select_value("SELECT #{mysql_function}") == 1
    end

    def unique_column_name
      "t#{SecureRandom.hex}"
    end
  end
end
