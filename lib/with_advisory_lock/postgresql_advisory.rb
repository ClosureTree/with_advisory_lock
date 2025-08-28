# frozen_string_literal: true

require 'securerandom'

module WithAdvisoryLock
  module PostgreSQLAdvisory
    extend ActiveSupport::Concern

    LOCK_PREFIX_ENV = 'WITH_ADVISORY_LOCK_PREFIX'
    LOCK_RESULT_VALUES = ['t', true].freeze
    ERROR_MESSAGE_REGEX = / ERROR: +current transaction is aborted,/

    def try_advisory_lock(lock_keys, lock_name:, shared:, transaction:, timeout_seconds: nil)
      # timeout_seconds is accepted for compatibility but ignored - PostgreSQL doesn't support
      # native timeouts with pg_try_advisory_lock, requiring Ruby-level polling instead
      function = advisory_try_lock_function(transaction, shared)
      execute_advisory(function, lock_keys, lock_name)
    end

    def release_advisory_lock(*args)
      # Handle both signatures - ActiveRecord's built-in and ours
      if args.length == 1 && args[0].is_a?(Integer)
        # ActiveRecord's built-in signature: release_advisory_lock(lock_id)
        super
      else
        # Our signature: release_advisory_lock(lock_keys, lock_name:, shared:, transaction:)
        lock_keys, options = args
        return if options[:transaction]

        function = advisory_unlock_function(options[:shared])
        execute_advisory(function, lock_keys, options[:lock_name])
      end
    rescue ActiveRecord::StatementInvalid => e
      # If the connection is broken, the lock is automatically released by PostgreSQL
      # No need to fail the release operation
      return if e.cause.is_a?(PG::ConnectionBad) || e.message =~ /PG::ConnectionBad/

      raise unless e.message =~ ERROR_MESSAGE_REGEX

      begin
        rollback_db_transaction
        execute_advisory(function, lock_keys, options[:lock_name])
      ensure
        begin_db_transaction
      end
    end

    def lock_keys_for(lock_name)
      [
        stable_hashcode(lock_name),
        ENV.fetch(LOCK_PREFIX_ENV, nil)
      ].map { |ea| ea.to_i & 0x7fffffff }
    end

    def supports_database_timeout?
      false
    end

    # Non-blocking check for advisory lock existence to avoid race conditions
    # This queries pg_locks directly instead of trying to acquire the lock
    def advisory_lock_exists_for?(lock_name, shared: false)
      lock_keys = lock_keys_for(lock_name)

      query = <<~SQL.squish
        SELECT 1 FROM pg_locks
        WHERE locktype = 'advisory'
          AND database = (SELECT oid FROM pg_database WHERE datname = CURRENT_DATABASE())
          AND classid = #{lock_keys.first}
          AND objid = #{lock_keys.last}
          AND mode = '#{shared ? 'ShareLock' : 'ExclusiveLock'}'
        LIMIT 1
      SQL

      query_value(query).present?
    rescue ActiveRecord::StatementInvalid
      # If pg_locks is not accessible, fall back to nil to indicate we should use the default method
      nil
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
      result = query_value(prepare_sql(function, lock_keys, lock_name))
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
