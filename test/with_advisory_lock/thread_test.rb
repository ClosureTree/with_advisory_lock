# frozen_string_literal: true

require 'test_helper'

module ThreadTestCases
  extend ActiveSupport::Concern

  included do
    self.use_transactional_tests = false

    setup do
      @lock_name = 'testing 1,2,3' # OMG COMMAS
      @mutex = Mutex.new
      @t1_acquired_lock = false
      @t1_return_value = nil

      @t1 = Thread.new do
        model_class.connection_pool.with_connection do
          @t1_return_value = model_class.with_advisory_lock(@lock_name) do
            @mutex.synchronize { @t1_acquired_lock = true }
            sleep
            't1 finished'
          end
        end
      end

      # Wait for the thread to acquire the lock:
      sleep(0.1) until @mutex.synchronize { @t1_acquired_lock }
      model_class.connection.reconnect!
    end

    teardown do
      @t1.wakeup if @t1.status == 'sleep'
      @t1.join
    end

    test '#with_advisory_lock with a 0 timeout returns false immediately' do
      response = model_class.with_advisory_lock(@lock_name, 0) do
        raise 'should not be yielded to'
      end
      assert_not(response)
    end

    test '#with_advisory_lock yields to the provided block' do
      assert(@t1_acquired_lock)
    end

    test '#advisory_lock_exists? returns true when another thread has the lock' do
      assert(model_class.advisory_lock_exists?(@lock_name))
    end

    test 'can re-establish the lock after the other thread releases it' do
      @t1.wakeup
      @t1.join
      assert_equal('t1 finished', @t1_return_value)

      # We should now be able to acquire the lock immediately:
      reacquired = false
      lock_result = model_class.with_advisory_lock(@lock_name, 0) do
        reacquired = true
      end

      assert(lock_result)
      assert(reacquired)
    end
  end
end

class PostgreSQLThreadTest < GemTestCase
  include ThreadTestCases

  def model_class
    Tag
  end
end

class MySQLThreadTest < GemTestCase
  include ThreadTestCases

  def model_class
    MysqlTag
  end
end

if GemTestCase.trilogy_available?
  class TrilogyThreadTest < GemTestCase
    include ThreadTestCases

    def model_class
      TrilogyTag
    end
  end
end
