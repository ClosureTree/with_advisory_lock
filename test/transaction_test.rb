# frozen_string_literal: true

require 'test_helper'

class TransactionScopingTest < GemTestCase
  def supported?
    %i[postgresql jdbcpostgresql].include?(env_db)
  end

  test 'raises an error when attempting to use transaction level locks if not supported' do
    skip if supported?

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
      skip unless env_db == :postgresql
      @pg_lock_count = lambda do
        ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM pg_locks WHERE locktype = 'advisory';").to_i
      end
    end

    test 'without timeout, the session locks release after the block executes' do
      Tag.transaction do
        assert_equal(0, @pg_lock_count.call)
        Tag.with_advisory_lock 'test' do
          assert_equal(1, @pg_lock_count.call)
        end
        assert_equal(0, @pg_lock_count.call)
      end
    end

    test 'with timeout, the session locks release after the block executes' do
      Tag.transaction do
        assert_equal(0, @pg_lock_count.call)
        Tag.with_advisory_lock 'test', timeout_seconds: 1  do
          assert_equal(1, @pg_lock_count.call)
        end
        assert_equal(0, @pg_lock_count.call)
      end
    end

    test 'without timeout, the session locks release when transaction fails inside block' do
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

    test 'with timeout, the session locks release when transaction fails inside block' do
      Tag.transaction do
        assert_equal(0, @pg_lock_count.call)

        exception = assert_raises(ActiveRecord::StatementInvalid) do
          Tag.with_advisory_lock 'test', timeout_seconds: 1 do
            Tag.connection.execute 'SELECT 1/0;'
          end
        end

        assert_match(/#{Regexp.escape('division by zero')}/, exception.message)
        assert_equal(0, @pg_lock_count.call)
      end
    end

    test 'without timeout, the transaction level locks hold until the transaction completes' do
      Tag.transaction do
        assert_equal(0, @pg_lock_count.call)
        Tag.with_advisory_lock 'test', transaction: true do
          assert_equal(1, @pg_lock_count.call)
        end
        assert_equal(1, @pg_lock_count.call)
      end
      assert_equal(0, @pg_lock_count.call)
    end

    test 'with timeout, the transaction level locks hold until the transaction completes' do
      Tag.transaction do
        assert_equal(0, @pg_lock_count.call)
        Tag.with_advisory_lock 'test', timeout_seconds: 1, transaction: true do
          assert_equal(1, @pg_lock_count.call)
        end
        assert_equal(1, @pg_lock_count.call)
      end
      assert_equal(0, @pg_lock_count.call)
    end
  end
end
