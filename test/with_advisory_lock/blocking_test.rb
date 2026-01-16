# frozen_string_literal: true

require 'test_helper'

# Universal blocking tests - work on all adapters
module BlockingTestCases
  extend ActiveSupport::Concern

  included do
    setup do
      @lock_name = 'test_blocking_lock'
    end

    test 'blocking lock acquires lock successfully' do
      result = model_class.with_advisory_lock(@lock_name, blocking: true) do
        'success'
      end
      assert_equal('success', result)
    end
  end
end

class PostgreSQLBlockingTest < GemTestCase
  include BlockingTestCases

  def model_class
    Tag
  end

  def setup
    super
    Tag.delete_all
  end

  test 'blocking lock waits for lock to be released' do
    lock_acquired = false
    thread1_finished = false

    thread1 = Thread.new do
      Tag.connection_pool.with_connection do
        Tag.transaction do
          Tag.with_advisory_lock(@lock_name, blocking: true, transaction: true) do
            lock_acquired = true
            sleep(0.5)
            thread1_finished = true
          end
        end
      end
    end

    sleep(0.1) until lock_acquired

    thread2_result = nil
    thread2 = Thread.new do
      Tag.connection_pool.with_connection do
        Tag.transaction do
          thread2_result = Tag.with_advisory_lock(@lock_name, blocking: true, transaction: true) do
            'thread2_success'
          end
        end
      end
    end

    thread1.join
    thread2.join

    assert(thread1_finished, 'Thread 1 should have finished')
    assert_equal('thread2_success', thread2_result, 'Thread 2 should have acquired lock after thread 1 released it')
  end

  test 'blocking lock can be used with shared locks' do
    thread1_result = nil
    thread2_result = nil

    thread1 = Thread.new do
      Tag.connection_pool.with_connection do
        Tag.transaction do
          thread1_result = Tag.with_advisory_lock(@lock_name, blocking: true, shared: true, transaction: true) do
            'shared1'
          end
        end
      end
    end

    thread2 = Thread.new do
      Tag.connection_pool.with_connection do
        Tag.transaction do
          thread2_result = Tag.with_advisory_lock(@lock_name, blocking: true, shared: true, transaction: true) do
            'shared2'
          end
        end
      end
    end

    thread1.join
    thread2.join

    assert_equal('shared1', thread1_result)
    assert_equal('shared2', thread2_result)
  end
end

class MySQLBlockingTest < GemTestCase
  include BlockingTestCases

  def model_class
    MysqlTag
  end

  def setup
    super
    MysqlTag.delete_all
  end
end

# Deadlock test requires non-transactional mode to work properly
class PostgreSQLDeadlockTest < GemTestCase
  self.use_transactional_tests = false

  def setup
    super
    @lock_name = 'test_blocking_lock'
    Tag.delete_all
  end

  test 'blocking lock detects deadlocks and returns false' do
    deadlock_detected = false
    thread1_started = Concurrent::AtomicBoolean.new(false)
    thread2_started = Concurrent::AtomicBoolean.new(false)

    thread1 = Thread.new do
      Tag.connection_pool.with_connection do
        Tag.transaction do
          Tag.with_advisory_lock('lock_a', blocking: true, transaction: true) do
            thread1_started.make_true
            sleep(0.1) until thread2_started.true?

            result = Tag.with_advisory_lock('lock_b', blocking: true, transaction: true) do
              'should_not_reach'
            end
            deadlock_detected = true if result == false
          end
        end
      rescue ActiveRecord::StatementInvalid => e
        deadlock_detected = true if e.message.downcase.include?('deadlock')
      end
    end

    thread2 = Thread.new do
      Tag.connection_pool.with_connection do
        Tag.transaction do
          Tag.with_advisory_lock('lock_b', blocking: true, transaction: true) do
            thread2_started.make_true
            sleep(0.1) until thread1_started.true?

            result = Tag.with_advisory_lock('lock_a', blocking: true, transaction: true) do
              'should_not_reach'
            end
            deadlock_detected = true if result == false
          end
        end
      rescue ActiveRecord::StatementInvalid => e
        deadlock_detected = true if e.message.downcase.include?('deadlock')
      end
    end

    joined1 = thread1.join(10)
    joined2 = thread2.join(10)

    unless joined1 && joined2
      thread1.kill if thread1.alive?
      thread2.kill if thread2.alive?
      flunk 'Deadlock detection timed out - threads did not complete within 10 seconds'
    end

    assert(deadlock_detected, 'Deadlock should have been detected by PostgreSQL')
  end
end
