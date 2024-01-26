# frozen_string_literal: true

require 'test_helper'

class SeparateThreadTest < GemTestCase
  setup do
    @lock_name = 'testing 1,2,3' # OMG COMMAS
    @mutex = Mutex.new
    @t1_acquired_lock = false
    @t1_locking = true
    @t1_return_value = nil

    @t1 = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        @t1_return_value = Label.with_advisory_lock(@lock_name) do
          @mutex.synchronize { @t1_acquired_lock = true }
          sleep(0.1) while @t1_locking
          't1 finished'
        end
      end
    end

    # Wait for the thread to acquire the lock:
    sleep(0.1) until @mutex.synchronize { @t1_acquired_lock }
    ActiveRecord::Base.connection.reconnect!
  end

  teardown do
    @t1_locking = false
    @t1.wakeup if @t1.status == 'sleep'
    @t1.join
  end

  test '#with_advisory_lock with no timeout waits until lock can be acquired, yields to the provided block, and then returns true' do
    yielded_to = false
    t2 = Thread.new { sleep(1); @t1_locking = false }
    start_time = Time.now

    response = Label.with_advisory_lock(@lock_name) do
      yielded_to = true
    end

    t2.join

    assert_in_delta(Time.now - start_time, 1, 0.5, "Expected with_advisory_lock to wait 1 second")
    assert(yielded_to, "Expected with_advisory_lock to yield to the block")
    assert(response, "Expect with_advisory_lock to return true")
  end

  test '#with_advisory_lock with a 0 timeout returns false immediately and does not yield to the provided block' do
    start_time = Time.now

    response = Label.with_advisory_lock(@lock_name, 0) do
      raise 'should not be yielded to'
    end

    assert_in_delta(Time.now - start_time, 0, 0.5, "Expected with_advisory_lock to return immediately")
    assert_not(response)
  end

  test '#with_advisory_lock with a 1 timeout waits 1 second, returns false, and does not yield to the provided block' do
    start_time = Time.now

    response = Label.with_advisory_lock(@lock_name, 1) do
      raise 'should not be yielded to'
    end

    assert_in_delta(Time.now - start_time, 1, 0.5, "Expected with_advisory_lock to wait 1 second")
    assert_not(response)
  end

  test '#with_advisory_lock yields to the provided block' do
    assert(@t1_acquired_lock)
  end

  test '#advisory_lock_exists? returns true when another thread has the lock' do
    assert(Tag.advisory_lock_exists?(@lock_name))
  end

  test 'can re-establish the lock after the other thread releases it' do
    @t1_locking = false
    @t1.wakeup
    @t1.join
    assert_equal('t1 finished', @t1_return_value)

    # We should now be able to acquire the lock immediately:
    reacquired = false
    lock_result = Label.with_advisory_lock(@lock_name, 0) do
      reacquired = true
    end

    assert(lock_result)
    assert(reacquired)
  end
end
