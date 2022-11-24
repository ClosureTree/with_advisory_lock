# frozen_string_literal: true

require 'minitest_helper'

describe 'class methods' do
  let(:lock_name) { 'test lock' }

  describe '.with_advisory_lock!' do

    it "does not throws for a succseful lock acquire" do
      assert_equal Tag.with_advisory_lock!(lock_name) { "BLOCK_RETURN" }, "BLOCK_RETURN"
    end

    it "does throws lock acquisting error when it fails to acquire a lock held by another thread" do
      Thread.new { Tag.with_advisory_lock!(lock_name, { timeout_seconds: 2 }) { sleep 2 } }
      error = assert_raises(WithAdvisoryLock::AdvisoryLockAcquistionError) do
        Tag.with_advisory_lock!(lock_name, { timeout_seconds: 1 }) { sleep 2 }
      end
      assert_equal "Failed to acquire lock for lock_name #{lock_name}", error.message
    end

    it "does not throws lock acquisting error for lock held by another thread if released before timeout" do
      Thread.new { Tag.with_advisory_lock!(lock_name, { timeout_seconds: 2 }) { sleep 0.5 } }
      assert_equal Tag.with_advisory_lock!(lock_name, { timeout_seconds: 1 }) { sleep 1; "BLOCK_RETURN" }, "BLOCK_RETURN"
    end
  end
end
