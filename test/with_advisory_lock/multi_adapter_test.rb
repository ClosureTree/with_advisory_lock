# frozen_string_literal: true

require 'test_helper'

class MultiAdapterIsolationTest < GemTestCase
  test 'postgresql and mysql adapters do not overlap' do
    lock_name = 'multi-adapter-lock'

    Tag.with_advisory_lock(lock_name) do
      assert MysqlTag.with_advisory_lock(lock_name, timeout_seconds: 0) { true }
    end

    MysqlTag.with_advisory_lock(lock_name) do
      assert Tag.with_advisory_lock(lock_name, timeout_seconds: 0) { true }
    end
  end
end
