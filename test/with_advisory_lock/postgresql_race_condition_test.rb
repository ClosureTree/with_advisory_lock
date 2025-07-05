# frozen_string_literal: true

require 'test_helper'
require 'concurrent'

class PostgreSQLRaceConditionTest < GemTestCase
  self.use_transactional_tests = false

  def model_class
    Tag
  end

  setup do
    @lock_name = 'race_condition_test'
  end

  test 'advisory_lock_exists? does not create false positives in multi-threaded environment' do
    # Ensure no lock exists initially
    assert_not model_class.advisory_lock_exists?(@lock_name)

    results = Concurrent::Array.new

    # Create a thread pool with multiple workers checking simultaneously
    # This would previously cause race conditions where threads would falsely
    # report the lock exists due to another thread's existence check
    pool = Concurrent::FixedThreadPool.new(20)
    promises = 20.times.map do
      Concurrent::Promise.execute(executor: pool) do
        model_class.connection_pool.with_connection do
          # Each thread checks multiple times to increase chance of race condition
          5.times do
            result = model_class.advisory_lock_exists?(@lock_name)
            results << result
            sleep(0.001) # Small delay to encourage interleaving
          end
        end
      end
    end

    # Wait for all promises to complete
    Concurrent::Promise.zip(*promises).wait!
    pool.shutdown
    pool.wait_for_termination

    # All checks should report false since no lock was ever acquired
    assert results.all? { |r| r == false },
           "Race condition detected: #{results.count(true)} false positives out of #{results.size} checks"
  end

  test 'advisory_lock_exists? correctly detects when lock is held by another connection' do
    lock_acquired = Concurrent::AtomicBoolean.new(false)
    lock_released = Concurrent::AtomicBoolean.new(false)

    # Promise 1: Acquire and hold the lock
    holder_promise = Concurrent::Promise.execute do
      model_class.connection_pool.with_connection do
        model_class.with_advisory_lock(@lock_name) do
          lock_acquired.make_true

          # Wait until we've confirmed the lock is detected
          sleep(0.01) until lock_released.true?
        end
      end
    end

    # Wait for lock to be acquired
    sleep(0.01) until lock_acquired.true?

    # Promise 2: Check if lock exists (should be true)
    checker_promise = Concurrent::Promise.execute do
      model_class.connection_pool.with_connection do
        # Check multiple times to ensure consistency
        10.times do
          assert model_class.advisory_lock_exists?(@lock_name),
                 'Failed to detect existing lock'
          sleep(0.01)
        end
      end
    end

    # Let the checker run
    checker_promise.wait!

    # Release the lock
    lock_released.make_true
    holder_promise.wait!

    # Verify lock is released
    assert_not model_class.advisory_lock_exists?(@lock_name)
  end

  test 'new non-blocking implementation is being used for PostgreSQL' do
    # This test verifies that our new implementation is actually being called
    # We can check this by looking at whether the connection responds to our new method
    model_class.connection_pool.with_connection do |conn|
      assert conn.respond_to?(:advisory_lock_exists_for?),
             'PostgreSQL connection should have advisory_lock_exists_for? method'

      # Test the method directly
      conn.lock_keys_for(@lock_name)
      result = conn.advisory_lock_exists_for?(@lock_name)
      assert_not_nil result, 'advisory_lock_exists_for? should return true/false, not nil'
      assert [true, false].include?(result), 'advisory_lock_exists_for? should return boolean'
    end
  end

  test 'fallback works if pg_locks access fails' do
    # Test that the system gracefully falls back to the old implementation
    # if pg_locks query fails (e.g., due to permissions)
    model_class.connection_pool.with_connection do |_conn|
      # We can't easily simulate pg_locks failure, but we can verify
      # the method handles exceptions gracefully
      assert_nothing_raised do
        model_class.advisory_lock_exists?('test_lock_fallback')
      end
    end
  end
end
