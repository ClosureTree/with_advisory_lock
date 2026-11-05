# frozen_string_literal: true

require 'test_helper'

class PostgreSQLTransactionScopingTest < GemTestCase
  self.use_transactional_tests = false

  setup do
    @pg_lock_count = lambda do
      backend_pid = Tag.connection.query_value('SELECT pg_backend_pid()')
      Tag.connection.query_value("SELECT COUNT(*) FROM pg_locks WHERE locktype = 'advisory' AND pid = #{backend_pid};").to_i
    end
  end

  test 'session locks release when transaction fails inside block' do
    Tag.transaction do
      assert_equal(0, @pg_lock_count.call)

      exception = assert_raises(ActiveRecord::StatementInvalid) do
        Tag.with_advisory_lock 'test' do
          Tag.connection.execute 'SELECT 1/0;'
        end
      end

      assert_match(/#{Regexp.escape('division by zero')}/, exception.message)
      assert_equal(0, @pg_lock_count.call)
    end
  end

  test 'raises an error when attempting to use transaction level locks outside a transaction' do
    exception = assert_raises(ArgumentError) do
      Tag.with_advisory_lock 'test', transaction: true do
        raise 'Thou shall not pass into this forbidden realm of code!'
      end
    end

    assert_match(/#{Regexp.escape('require an active transaction')}/, exception.message)
  end

  test 'transaction level try locks are held until the transaction ends' do
    assert_equal(false, try_lock_while_held(shared: false))
  end

  test 'transaction level shared try locks are held until the transaction ends' do
    assert_equal(false, try_lock_while_held(shared: true))
  end

  private

  # The first thread takes the lock as the first statement of its transaction and holds it
  # while a second thread tries the same lock exclusively.
  def try_lock_while_held(shared:)
    locked = Queue.new
    release = Queue.new
    holder = Thread.new do
      Tag.connection_pool.with_connection do
        Tag.transaction do
          Tag.with_advisory_lock('transaction_try_lock', transaction: true, shared: shared, timeout_seconds: 0) do
            locked << true
            release.pop
          end
        end
      end
    ensure
      locked << false
    end
    assert(locked.pop, 'holder did not take the lock')

    Thread.new do
      Tag.connection_pool.with_connection do
        Tag.transaction do
          Tag.with_advisory_lock('transaction_try_lock', transaction: true, timeout_seconds: 0) { true }
        end
      end
    end.value
  ensure
    release << true
    holder.join
  end
end

class MySQLTransactionScopingTest < GemTestCase
  self.use_transactional_tests = false

  test 'raises an error when attempting to use transaction level locks' do
    MysqlTag.transaction do
      exception = assert_raises(ArgumentError) do
        MysqlTag.with_advisory_lock 'test', transaction: true do
          raise 'Behold! Thou hath trespassed into the sacred MySQL transaction realm!'
        end
      end

      assert_match(/#{Regexp.escape('not supported')}/, exception.message)
    end
  end

  test 'session locks work within transactions' do
    lock_acquired = false
    MysqlTag.transaction do
      MysqlTag.with_advisory_lock 'test' do
        lock_acquired = true
      end
    end
    assert lock_acquired
  end

  test 'raises an error when attempting to use transaction level locks outside a transaction' do
    exception = assert_raises(ArgumentError) do
      MysqlTag.with_advisory_lock 'test', transaction: true do
        raise 'Verily, thou art banished from these hallowed database gates!'
      end
    end

    assert_match(/#{Regexp.escape('require an active transaction')}/, exception.message)
  end
end

if GemTestCase.trilogy_available?
  class TrilogyTransactionScopingTest < GemTestCase
    self.use_transactional_tests = false

    test 'raises an error when attempting to use transaction level locks' do
      TrilogyTag.transaction do
        exception = assert_raises(ArgumentError) do
          TrilogyTag.with_advisory_lock 'test', transaction: true do
            raise 'Trilogy transaction realm is forbidden!'
          end
        end

        assert_match(/#{Regexp.escape('not supported')}/, exception.message)
      end
    end

    test 'session locks work within transactions' do
      lock_acquired = false
      TrilogyTag.transaction do
        TrilogyTag.with_advisory_lock 'test' do
          lock_acquired = true
        end
      end
      assert lock_acquired
    end

    test 'raises an error when attempting to use transaction level locks outside a transaction' do
      exception = assert_raises(ArgumentError) do
        TrilogyTag.with_advisory_lock 'test', transaction: true do
          raise 'Trilogy gates are closed!'
        end
      end

      assert_match(/#{Regexp.escape('require an active transaction')}/, exception.message)
    end
  end
end
