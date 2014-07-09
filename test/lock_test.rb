require 'minitest_helper'

describe 'class methods' do
  let(:lock_name) { "test lock #{rand(1024)}" }
  let(:expected_lock_name) { "#{ENV['WITH_ADVISORY_LOCK_PREFIX']}#{lock_name}" }

  describe '.current_advisory_lock' do
    it "returns nil outside an advisory lock request" do
      Tag.current_advisory_lock.must_be_nil
    end

    it 'returns the name of the last lock acquired' do
      Tag.with_advisory_lock(lock_name) do
        Tag.current_advisory_lock.must_equal expected_lock_name
      end
    end
  end

  describe '.advisory_lock_exists?' do
    it "returns false for an unacquired lock" do
      Tag.advisory_lock_exists?(expected_lock_name).must_be_false
    end

    it 'returns the name of the last lock acquired' do
      Tag.with_advisory_lock(lock_name) do
        Tag.advisory_lock_exists?(lock_name).must_be_true
      end
    end
  end

  describe "0 timeout" do
    it 'attempts the lock exactly once with no timeout' do
      block_was_yielded = false
      Tag.with_advisory_lock(lock_name, 0) do
        block_was_yielded = true
      end
      block_was_yielded.must_be_true
    end
  end
end
