# frozen_string_literal: true

require 'test_helper'
class SharedTestWorker
  def initialize(shared)
    @shared = shared

    @locked = nil
    @cleanup = false
    @thread = Thread.new { work }
  end

  def locked?
    sleep 0.01 while @locked.nil? && @thread.alive?
    @locked
  end

  def cleanup!
    @cleanup = true
    @thread.join
    raise if @thread.status.nil?
  end

  private

  def work
    ActiveRecord::Base.connection_pool.with_connection do
      Tag.with_advisory_lock('test', timeout_seconds: 0, shared: @shared) do
        @locked = true
        sleep 0.01 until @cleanup
      end
      @locked = false
      sleep 0.01 until @cleanup
    end
  end
end

class SharedLocksTest < GemTestCase
  def supported?
    %i[trilogy mysql2 jdbcmysql].exclude?(env_db)
  end

  test 'does not allow two exclusive locks' do
    one = SharedTestWorker.new(false)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(false)
    refute(two.locked?)

    one.cleanup!
    two.cleanup!
  end
end

class NotSupportedEnvironmentTest < SharedLocksTest
  setup do
    skip if supported?
  end

  test 'raises an error when attempting to use a shared lock' do
    one = SharedTestWorker.new(true)
    assert_nil(one.locked?)

    exception = assert_raises(ArgumentError) do
      one.cleanup!
    end

    assert_match(/#{Regexp.escape('not supported')}/, exception.message)
  end
end

class SupportedEnvironmentTest < SharedLocksTest
  setup do
    skip unless supported?
  end

  test 'does allow two shared locks' do
    one = SharedTestWorker.new(true)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(true)
    assert_predicate(two, :locked?)

    one.cleanup!
    two.cleanup!
  end

  test 'does not allow exclusive lock with shared lock' do
    one = SharedTestWorker.new(true)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(false)
    refute(two.locked?)

    three = SharedTestWorker.new(true)
    assert_predicate(three, :locked?)

    one.cleanup!
    two.cleanup!
    three.cleanup!
  end

  test 'does not allow shared lock with exclusive lock' do
    one = SharedTestWorker.new(false)
    assert_predicate(one, :locked?)

    two = SharedTestWorker.new(true)
    refute(two.locked?)

    one.cleanup!
    two.cleanup!
  end

  class PostgreSQLTest < SupportedEnvironmentTest
    setup do
      skip unless env_db == :postgresql
    end

    def pg_lock_modes
      ActiveRecord::Base.connection.select_values("SELECT mode FROM pg_locks WHERE locktype = 'advisory';")
    end

    test 'allows shared lock to be upgraded to an exclusive lock' do
      assert_empty(pg_lock_modes)
      Tag.with_advisory_lock 'test', shared: true do
        assert_equal(%w[ShareLock], pg_lock_modes)
        Tag.with_advisory_lock 'test', shared: false do
          assert_equal(%w[ShareLock ExclusiveLock], pg_lock_modes)
        end
      end
      assert_empty(pg_lock_modes)
    end
  end
end
