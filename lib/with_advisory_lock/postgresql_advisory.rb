# frozen_string_literal: true

require 'securerandom'

module WithAdvisoryLock
  module PostgreSQLAdvisory
    extend ActiveSupport::Concern

    LOCK_RESULT_VALUES = ['t', true].freeze
    ERROR_MESSAGE_REGEX = / ERROR: +current transaction is aborted,/

    def try_advisory_lock(lock_keys, lock_name:, shared:, transaction:, timeout_seconds: nil, blocking: false)
      function = if blocking
                   advisory_lock_function(transaction, shared)
                 else
                   advisory_try_lock_function(transaction, shared)
                 end

      if blocking && timeout_seconds&.positive?
        blocking_lock_with_timeout(function, lock_keys, lock_name, timeout_seconds)
      else
        execute_advisory(function, lock_keys, lock_name, blocking: blocking)
      end
    rescue ActiveRecord::Deadlocked
      # Rails 8.2+ raises ActiveRecord::Deadlocked directly for PostgreSQL deadlocks
      # When using blocking locks, treat deadlocks as lock acquisition failure
      return false if blocking

      raise
    rescue ActiveRecord::StatementInvalid => e
      # PostgreSQL deadlock detection raises PG::TRDeadlockDetected (SQLSTATE 40P01)
      # When using blocking locks, treat deadlocks as lock acquisition failure.
      # Rails 8.2+ may also retry after deadlock and get "current transaction is aborted"
      # when the transaction was rolled back by PostgreSQL's deadlock detection.
      if blocking && (e.cause.is_a?(PG::TRDeadlockDetected) ||
                      e.message.include?('deadlock detected') ||
                      e.message =~ ERROR_MESSAGE_REGEX)
        false
      else
        raise
      end
    end

    def release_advisory_lock(*args)
      # ActiveRecord's built-in signature: release_advisory_lock(lock_id)
      return super if args.length == 1 && args[0].is_a?(Integer)

      # Our signature: release_advisory_lock(lock_keys, lock_name:, shared:, transaction:)
      lock_keys, options = args
      return if options[:transaction]

      function = advisory_unlock_function(options[:shared])
      begin
        execute_advisory(function, lock_keys, options[:lock_name])
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
    end

    def lock_keys_for(lock_name)
      [
        stable_hashcode(lock_name),
        ENV.fetch(CoreAdvisory::LOCK_PREFIX_ENV, nil)
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
          AND granted
        LIMIT 1
      SQL

      query_value(query).present?
    rescue ActiveRecord::StatementInvalid
      # If pg_locks is not accessible, fall back to nil to indicate we should use the default method
      nil
    end

    private

    # Bounded blocking acquisition via SET LOCAL lock_timeout. The setting is
    # transaction-scoped so it never leaks to the session (pooler-safe), and
    # the savepoint keeps a timeout from aborting an enclosing transaction.
    # Session-level locks acquired here survive the wrapping COMMIT.
    def blocking_lock_with_timeout(function, lock_keys, lock_name, timeout_seconds)
      transaction(requires_new: true) do
        previous_timeout = query_value('SHOW lock_timeout')
        execute("SET LOCAL lock_timeout = '#{(timeout_seconds * 1000).to_i}ms'")
        execute_advisory(function, lock_keys, lock_name, blocking: true)
        # SET LOCAL survives a released savepoint, so restore the outer value
        execute("SET LOCAL lock_timeout = #{quote(previous_timeout)}")
        true
      end
    rescue ActiveRecord::LockWaitTimeout
      false
    end

    def advisory_try_lock_function(transaction_scope, shared)
      [
        'pg_try_advisory',
        transaction_scope ? '_xact' : nil,
        '_lock',
        shared ? '_shared' : nil
      ].compact.join
    end

    def advisory_lock_function(transaction_scope, shared)
      [
        'pg_advisory',
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

    def execute_advisory(function, lock_keys, lock_name, blocking: false)
      sql = prepare_sql(function, lock_keys, lock_name)
      if blocking
        # Blocking locks return void - if the query executes successfully, the lock was acquired.
        # Rails 8.2+ uses lazy transaction materialization. We must use materialize_transactions: true
        # to ensure the transaction is started on the database before acquiring the lock,
        # otherwise the lock won't actually block other connections.
        if respond_to?(:internal_exec_query, true)
          # Rails < 8.2
          query_value(sql)
        else
          # Rails 8.2+ - use query_all with materialize_transactions: true
          send(:query_all, sql, 'AdvisoryLock', materialize_transactions: true)
        end
        true
      else
        # Non-blocking try locks return boolean
        result = query_value(sql)
        LOCK_RESULT_VALUES.include?(result)
      end
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
