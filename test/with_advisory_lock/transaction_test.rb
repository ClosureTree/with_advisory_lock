# frozen_string_literal: true

require 'test_helper'

class TransactionScopingTest < GemTestCase
  test 'raises an error when attempting to use transaction level locks if not supported' do
    skip if is_postgresql_adapter?

    Tag.transaction do
      exception = assert_raises(ArgumentError) do
        Tag.with_advisory_lock 'test', transaction: true do
          raise 'should not get here'
        end
      end

      assert_match(/#{Regexp.escape('not supported')}/, exception.message)
    end
  end

  class PostgresqlTest < TransactionScopingTest
    setup do
      skip unless is_postgresql_adapter?
      @pg_lock_count = lambda do
        ApplicationRecord.connection.select_value("SELECT COUNT(*) FROM pg_locks WHERE locktype = 'advisory';").to_i
      end
    end

    test 'session locks release after the block executes' do
      Tag.transaction do
        assert_equal(0, @pg_lock_count.call)
        Tag.with_advisory_lock 'test' do
          assert_equal(1, @pg_lock_count.call)
        end
        assert_equal(0, @pg_lock_count.call)
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

    test 'transaction level locks hold until the transaction completes' do
      Tag.transaction do
        assert_equal(0, @pg_lock_count.call)
        Tag.with_advisory_lock 'test', transaction: true do
          assert_equal(1, @pg_lock_count.call)
        end
        assert_equal(1, @pg_lock_count.call)
      end
      assert_equal(0, @pg_lock_count.call)
    end
  end
end
