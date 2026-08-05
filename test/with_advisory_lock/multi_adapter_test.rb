# frozen_string_literal: true

require 'test_helper'

# Database-level assertions so these tests cannot pass without real lock acquisition
module AdapterLockAssertions
  def assert_mysql_lock_held(model, lock_name)
    model.with_connection do |conn|
      key = conn.lock_keys_for(lock_name).first
      assert_not_nil conn.query_value("SELECT IS_USED_LOCK(#{conn.quote(key)})"),
                     "#{model.name} should hold GET_LOCK(#{key.inspect}) at the database level"
    end
  end

  def assert_pg_lock_held(model, lock_name)
    model.with_connection do |conn|
      assert conn.advisory_lock_exists_for?(lock_name),
             "#{model.name} should hold the advisory lock in pg_locks"
    end
  end
end

class MultiAdapterIsolationTest < GemTestCase
  include AdapterLockAssertions

  test 'postgresql and mysql adapters do not overlap' do
    lock_name = 'multi-adapter-lock'

    # PostgreSQL lock doesn't block MySQL
    Tag.with_advisory_lock(lock_name) do
      acquired = MysqlTag.with_advisory_lock(lock_name, timeout_seconds: 0) do
        assert_mysql_lock_held(MysqlTag, lock_name)
        true
      end
      assert acquired
    end

    # MySQL lock doesn't block PostgreSQL
    MysqlTag.with_advisory_lock(lock_name) do
      acquired = Tag.with_advisory_lock(lock_name, timeout_seconds: 0) do
        assert_pg_lock_held(Tag, lock_name)
        true
      end
      assert acquired
    end
  end
end

if GemTestCase.trilogy_available?
  class TrilogyMultiAdapterIsolationTest < GemTestCase
    include AdapterLockAssertions
    test 'trilogy adapter does not overlap with postgresql or mysql' do
      lock_name = 'multi-adapter-lock'

      # PostgreSQL lock doesn't block Trilogy
      Tag.with_advisory_lock(lock_name) do
        acquired = TrilogyTag.with_advisory_lock(lock_name, timeout_seconds: 0) do
          assert_mysql_lock_held(TrilogyTag, lock_name)
          true
        end
        assert acquired
      end

      # Trilogy lock doesn't block PostgreSQL
      TrilogyTag.with_advisory_lock(lock_name) do
        acquired = Tag.with_advisory_lock(lock_name, timeout_seconds: 0) do
          assert_pg_lock_held(Tag, lock_name)
          true
        end
        assert acquired
      end

      # MySQL lock doesn't block Trilogy
      MysqlTag.with_advisory_lock(lock_name) do
        acquired = TrilogyTag.with_advisory_lock(lock_name, timeout_seconds: 0) do
          assert_mysql_lock_held(TrilogyTag, lock_name)
          true
        end
        assert acquired
      end

      TrilogyTag.with_advisory_lock(lock_name) do
        acquired = MysqlTag.with_advisory_lock(lock_name, timeout_seconds: 0) do
          assert_mysql_lock_held(MysqlTag, lock_name)
          true
        end
        assert acquired
      end
    end
  end
end
