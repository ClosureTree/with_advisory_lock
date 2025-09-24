# frozen_string_literal: true

require 'test_helper'

class MultiAdapterIsolationTest < GemTestCase
  test 'postgresql, mysql, and trilogy adapters do not overlap' do
    lock_name = 'multi-adapter-lock'

    # PostgreSQL lock doesn't block MySQL
    Tag.with_advisory_lock(lock_name) do
      assert MysqlTag.with_advisory_lock(lock_name, timeout_seconds: 0) { true }
    end

    # MySQL lock doesn't block PostgreSQL
    MysqlTag.with_advisory_lock(lock_name) do
      assert Tag.with_advisory_lock(lock_name, timeout_seconds: 0) { true }
    end

    # PostgreSQL lock doesn't block Trilogy
    Tag.with_advisory_lock(lock_name) do
      assert TrilogyTag.with_advisory_lock(lock_name, timeout_seconds: 0) { true }
    end

    # Trilogy lock doesn't block PostgreSQL
    TrilogyTag.with_advisory_lock(lock_name) do
      assert Tag.with_advisory_lock(lock_name, timeout_seconds: 0) { true }
    end

    # MySQL lock doesn't block Trilogy
    MysqlTag.with_advisory_lock(lock_name) do
      assert TrilogyTag.with_advisory_lock(lock_name, timeout_seconds: 0) { true }
    end

    # Trilogy lock doesn't block MySQL
    TrilogyTag.with_advisory_lock(lock_name) do
      assert MysqlTag.with_advisory_lock(lock_name, timeout_seconds: 0) { true }
    end
  end
end
