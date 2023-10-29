# frozen_string_literal: true

require 'test_helper'

class LockTest < GemTestCase
  setup do
    @lock_name = 'test lock'
    @return_val = 1900
  end

  test 'returns nil outside an advisory lock request' do
    assert_nil(Tag.current_advisory_lock)
  end

  test 'returns the name of the last lock acquired' do
    Tag.with_advisory_lock(@lock_name) do
      assert_match(/#{@lock_name}/, Tag.current_advisory_lock)
    end
  end

  test 'can obtain a lock with a name that attempts to disrupt a SQL comment' do
    dangerous_lock_name = 'test */ lock /*'
    Tag.with_advisory_lock(dangerous_lock_name) do
      assert_match(/#{Regexp.escape(dangerous_lock_name)}/, Tag.current_advisory_lock)
    end
  end

  test 'returns false for an unacquired lock' do
    refute(Tag.advisory_lock_exists?(@lock_name))
  end

  test 'returns true for an acquired lock' do
    Tag.with_advisory_lock(@lock_name) do
      assert(Tag.advisory_lock_exists?(@lock_name))
    end
  end

  test 'returns block return value if lock successful' do
    assert_equal(@return_val, Tag.with_advisory_lock!(@lock_name) { @return_val })
  end

  test 'returns false on lock acquisition failure' do
    thread_with_lock = Thread.new do
      Tag.with_advisory_lock(@lock_name, timeout_seconds: 0) do
        @locked_elsewhere = true
        loop { sleep 0.01 }
      end
    end

    sleep 0.01 until @locked_elsewhere
    assert_not(Tag.with_advisory_lock(@lock_name, timeout_seconds: 0) { @return_val })

    thread_with_lock.kill
  end

  test 'raises an error on lock acquisition failure' do
    thread_with_lock = Thread.new do
      Tag.with_advisory_lock(@lock_name, timeout_seconds: 0) do
        @locked_elsewhere = true
        loop { sleep 0.01 }
      end
    end

    sleep 0.01 until @locked_elsewhere
    assert_raises(WithAdvisoryLock::FailedToAcquireLock) do
      Tag.with_advisory_lock!(@lock_name, timeout_seconds: 0) { @return_val }
    end

    thread_with_lock.kill
  end

  test 'attempts the lock exactly once with no timeout' do
    expected = SecureRandom.base64
    actual = Tag.with_advisory_lock(@lock_name, 0) do
      expected
    end

    assert_equal(expected, actual)
  end
end
