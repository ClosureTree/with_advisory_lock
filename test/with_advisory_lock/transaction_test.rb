# frozen_string_literal: true

require 'test_helper'

class PostgreSQLTransactionScopingTest < GemTestCase
  self.use_transactional_tests = false

  setup do
    @pg_lock_count = lambda do
      backend_pid = Tag.connection.select_value('SELECT pg_backend_pid()')
      Tag.connection.select_value("SELECT COUNT(*) FROM pg_locks WHERE locktype = 'advisory' AND pid = #{backend_pid};").to_i
    end
  end

  test 'session locks release after the block executes' do
    skip 'PostgreSQL lock visibility issue - locks acquired via advisory lock methods not showing in pg_locks'
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

  test 'transaction level locks hold until the transaction completes' do
    skip 'PostgreSQL lock visibility issue - locks acquired via advisory lock methods not showing in pg_locks'
  end
end

class MySQLTransactionScopingTest < GemTestCase
  self.use_transactional_tests = false

  test 'raises an error when attempting to use transaction level locks' do
    MysqlTag.transaction do
      exception = assert_raises(ArgumentError) do
        MysqlTag.with_advisory_lock 'test', transaction: true do
          raise 'should not get here'
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
end
