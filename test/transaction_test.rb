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
        exception = _(proc {
          Tag.with_advisory_lock 'test', transaction: true do
            raise 'should not get here'
          end
        }).must_raise ArgumentError
        _(exception.message).must_include 'not supported'
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
        _(pg_lock_count).must_equal 0
        Tag.with_advisory_lock 'test' do
          _(pg_lock_count).must_equal 1
        end
        _(pg_lock_count).must_equal 0
      end
    end

    specify 'session locks release when transaction fails inside block' do
      Tag.transaction do
        _(pg_lock_count).must_equal 0

        exception = _(proc {
          Tag.with_advisory_lock 'test' do
            Tag.connection.execute 'SELECT 1/0;'
          end
        }).must_raise ActiveRecord::StatementInvalid
        _(exception.message).must_include 'division by zero'

        _(pg_lock_count).must_equal 0
      end
    end

    specify 'transaction level locks hold until the transaction completes' do
      Tag.transaction do
        _(pg_lock_count).must_equal 0
        Tag.with_advisory_lock 'test', transaction: true do
          _(pg_lock_count).must_equal 1
        end
        _(pg_lock_count).must_equal 1
      end
      _(pg_lock_count).must_equal 0
    end
  end
end
