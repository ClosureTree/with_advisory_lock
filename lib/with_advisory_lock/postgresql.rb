# frozen_string_literal: true

require 'securerandom'

module WithAdvisoryLock
  # Methods mixed into the PostgreSQL connection adapter to provide advisory
  # locking support. The public API mirrors the methods expected by
  # +WithAdvisoryLock::Base+.
  module PostgreSQL
    extend ActiveSupport::Concern

    LOCK_RESULT_VALUES = ['t', true].freeze
    ERROR_MESSAGE_REGEX = / ERROR: +current transaction is aborted,/

    def try_advisory_lock(lock_keys, lock_name:, shared:, transaction:)
      function = advisory_try_lock_function(transaction, shared)
      execute_advisory(function, lock_keys, lock_name)
    end

    def release_advisory_lock(lock_keys, lock_name:, shared:, transaction:)
      return if transaction

      function = advisory_unlock_function(shared)
      execute_advisory(function, lock_keys, lock_name)
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ ERROR_MESSAGE_REGEX

      begin
        rollback_db_transaction
        execute_advisory(function, lock_keys, lock_name)
      ensure
        begin_db_transaction
      end
    end

    private

    def advisory_try_lock_function(transaction_scope, shared)
      [
        'pg_try_advisory',
        transaction_scope ? '_xact' : nil,
        '_lock',
        shared ? '_shared' : nil
      ].compact.join
    end

    def advisory_unlock_function(shared)
      [
        'pg_advisory_unlock',
        shared ? '_shared' : nil
      ].compact.join
    end

    def execute_advisory(function, lock_keys, lock_name)
      result = select_value(prepare_sql(function, lock_keys, lock_name))
      LOCK_RESULT_VALUES.include?(result)
    end

    def prepare_sql(function, lock_keys, lock_name)
      comment = lock_name.to_s.gsub(%r{(/\*)|(\*/)}, '--')
      "SELECT #{function}(#{lock_keys.join(',')}) AS #{unique_column_name} /* #{comment} */"
    end

    def unique_column_name
      "t#{SecureRandom.hex}"
    end
  end
end
