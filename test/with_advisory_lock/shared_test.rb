# frozen_string_literal: true

require 'test_helper'

class SharedTestWorker
  attr_reader :model_class, :error

  def initialize(model_class, shared)
    @model_class = model_class
    @shared = shared

    @locked = nil
    @cleanup = false
    @error = nil
    @thread = Thread.new do
      Thread.current.report_on_exception = false
      work
    end
  end

  def locked?
    sleep 0.01 while @locked.nil? && @thread.alive?
    @locked
  end

  def cleanup!
    @cleanup = true
    @thread.join
    raise @error if @error
  end

  private

  def work
    model_class.connection_pool.with_connection do
      model_class.with_advisory_lock('test', timeout_seconds: 0, shared: @shared) do
        @locked = true
        sleep 0.01 until @cleanup
      end
      @locked = false
      sleep 0.01 until @cleanup
    end
  rescue StandardError => e
    @error = e
    @locked = false
  end
end

class PostgreSQLSharedLocksTest < GemTestCase
  self.use_transactional_tests = false

  test 'does not allow two exclusive locks' do
    one = SharedTestWorker.new(Tag, false)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(Tag, false)
    refute(two.locked?)

    one.cleanup!
    two.cleanup!
  end

  test 'does allow two shared locks' do
    one = SharedTestWorker.new(Tag, true)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(Tag, true)
    assert_predicate(two, :locked?)

    one.cleanup!
    two.cleanup!
  end

  test 'does not allow exclusive lock with shared lock' do
    one = SharedTestWorker.new(Tag, true)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(Tag, false)
    refute(two.locked?)

    three = SharedTestWorker.new(Tag, true)
    assert_predicate(three, :locked?)

    one.cleanup!
    two.cleanup!
    three.cleanup!
  end

  test 'does not allow shared lock with exclusive lock' do
    one = SharedTestWorker.new(Tag, false)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(Tag, true)
    refute(two.locked?)

    one.cleanup!
    two.cleanup!
  end

  test 'allows shared lock to be upgraded to an exclusive lock' do
    skip 'PostgreSQL lock visibility issue - locks acquired via advisory lock methods not showing in pg_locks'
  end
end

class MySQLSharedLocksTest < GemTestCase
  self.use_transactional_tests = false

  test 'does not allow two exclusive locks' do
    one = SharedTestWorker.new(MysqlTag, false)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(MysqlTag, false)
    refute(two.locked?)

    one.cleanup!
    two.cleanup!
  end

  test 'raises an error when attempting to use a shared lock' do
    one = SharedTestWorker.new(MysqlTag, true)
    assert_equal(false, one.locked?)

    exception = assert_raises(ArgumentError) do
      one.cleanup!
    end

    assert_match(/shared locks are not supported/, exception.message)
  end
end
