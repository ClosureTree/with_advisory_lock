# frozen_string_literal: true

require 'minitest_helper'

describe 'transaction scoping' do
  def supported?
    env_db == :postgresql
  end

  describe 'not supported' do
    before do
      skip if supported?
    end

    it 'raises an error when attempting to use transaction level locks' do
      Tag.transaction do
        exception = assert_raises(ArgumentError) do
          Tag.with_advisory_lock 'test', transaction: true do
            raise 'should not get here'
          end
        end

        assert_match(/#{Regexp.escape('not supported')}/, exception.message)
      end
    end
  end

  describe 'supported' do
    before do
      skip unless env_db == :postgresql
    end

    def pg_lock_count
      ActiveRecord::Base.connection.select_value("SELECT COUNT(*) FROM pg_locks WHERE locktype = 'advisory';").to_i
    end

    specify 'session locks release after the block executes' do
      Tag.transaction do
        assert_equal(0, pg_lock_count)
        Tag.with_advisory_lock 'test' do
          assert_equal(1, pg_lock_count)
        end
        assert_equal(0, pg_lock_count)
      end
    end

    specify 'session locks release when transaction fails inside block' do
      Tag.transaction do
        assert_equal(0, pg_lock_count)

        exception = assert_raises(ActiveRecord::StatementInvalid) do
          Tag.with_advisory_lock 'test' do
            Tag.connection.execute 'SELECT 1/0;'
          end
        end

        assert_match(/#{Regexp.escape('division by zero')}/, exception.message)
        assert_equal(0, pg_lock_count)
      end
    end

    specify 'transaction level locks hold until the transaction completes' do
      Tag.transaction do
        assert_equal(0, pg_lock_count)
        Tag.with_advisory_lock 'test', transaction: true do
          assert_equal(1, pg_lock_count)
        end
        assert_equal(1, pg_lock_count)
      end
      assert_equal(0, pg_lock_count)
    end
  end
end
