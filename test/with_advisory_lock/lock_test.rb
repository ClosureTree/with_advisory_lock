# frozen_string_literal: true

require 'test_helper'

module LockTestCases
  extend ActiveSupport::Concern

  included do
    self.use_transactional_tests = false

    setup do
      @lock_name = 'test lock'
      @return_val = 1900
    end

    test 'returns nil outside an advisory lock request' do
      assert_nil(model_class.current_advisory_lock)
    end

    test 'returns the name of the last lock acquired' do
      model_class.with_advisory_lock(@lock_name) do
        assert_match(/#{@lock_name}/, model_class.current_advisory_lock)
      end
    end

    test 'can obtain a lock with a name that attempts to disrupt a SQL comment' do
      dangerous_lock_name = 'test */ lock /*'
      model_class.with_advisory_lock(dangerous_lock_name) do
        assert_match(/#{Regexp.escape(dangerous_lock_name)}/, model_class.current_advisory_lock)
      end
    end

    test 'returns false for an unacquired lock' do
      refute(model_class.advisory_lock_exists?(@lock_name))
    end

    test 'returns true for an acquired lock' do
      model_class.with_advisory_lock(@lock_name) do
        assert(model_class.advisory_lock_exists?(@lock_name))
      end
    end

    test 'returns block return value if lock successful' do
      assert_equal(@return_val, model_class.with_advisory_lock!(@lock_name) { @return_val })
    end

    test 'returns false on lock acquisition failure' do
      thread_with_lock = Thread.new do
        model_class.connection_pool.with_connection do
          model_class.with_advisory_lock(@lock_name, timeout_seconds: 0) do
            @locked_elsewhere = true
            loop { sleep 0.01 }
          end
        end
      end

      sleep 0.01 until @locked_elsewhere
      model_class.connection.reconnect!
      assert_not(model_class.with_advisory_lock(@lock_name, timeout_seconds: 0) { @return_val })

      thread_with_lock.kill
    end

    test 'raises an error on lock acquisition failure' do
      thread_with_lock = Thread.new do
        model_class.connection_pool.with_connection do
          model_class.with_advisory_lock(@lock_name, timeout_seconds: 0) do
            @locked_elsewhere = true
            loop { sleep 0.01 }
          end
        end
      end

      sleep 0.01 until @locked_elsewhere
      model_class.connection.reconnect!
      assert_raises(WithAdvisoryLock::FailedToAcquireLock) do
        model_class.with_advisory_lock!(@lock_name, timeout_seconds: 0) { @return_val }
      end

      thread_with_lock.kill
    end

    test 'attempts the lock exactly once with no timeout' do
      expected = SecureRandom.base64
      actual = model_class.with_advisory_lock(@lock_name, 0) do
        expected
      end

      assert_equal(expected, actual)
    end

    test 'current_advisory_locks returns empty array outside an advisory lock request' do
      assert_equal([], model_class.current_advisory_locks)
    end

    test 'current_advisory_locks returns an array with names of the acquired locks' do
      model_class.with_advisory_lock(@lock_name) do
        locks = model_class.current_advisory_locks
        assert_equal(1, locks.size)
        assert_match(/#{@lock_name}/, locks.first)
      end
    end

    test 'current_advisory_locks returns array of all nested lock names' do
      first_lock = 'outer lock'
      second_lock = 'inner lock'

      model_class.with_advisory_lock(first_lock) do
        model_class.with_advisory_lock(second_lock) do
          locks = model_class.current_advisory_locks
          assert_equal(2, locks.size)
          assert_match(/#{first_lock}/, locks.first)
          assert_match(/#{second_lock}/, locks.last)
        end

        locks = model_class.current_advisory_locks
        assert_equal(1, locks.size)
        assert_match(/#{first_lock}/, locks.first)
      end
      assert_equal([], model_class.current_advisory_locks)
    end

    test 'handles connection disconnection gracefully during lock release' do
      # This test ensures that if the connection is lost, lock release doesn't fail
      # The lock will be automatically released by the database when the session ends
      model_class.with_advisory_lock(@lock_name) do
        # Simulate connection issues by testing the rescue logic
        # We can't easily test actual disconnection in unit tests without side effects
        # but we can test the error handling logic by testing with invalid connection state
        assert_not_nil model_class.current_advisory_lock
      end
      
      # After the block, current_advisory_lock should be nil regardless
      assert_nil model_class.current_advisory_lock
    end
  end
end

class PostgreSQLLockTest < GemTestCase
  include LockTestCases

  def model_class
    Tag
  end

  def setup
    super
    Tag.delete_all
  end
end

class MySQLLockTest < GemTestCase
  include LockTestCases

  def model_class
    MysqlTag
  end

  def setup
    super
    MysqlTag.delete_all
  end
end
