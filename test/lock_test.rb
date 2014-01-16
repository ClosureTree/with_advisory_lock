require 'minitest_helper'

describe 'class methods' do

  let(:lock_name) { "test lock #{rand(1024)}" }

  describe '.current_advisory_lock' do
    it "returns nil outside an advisory lock request" do
      Tag.current_advisory_lock.must_be_nil
    end

    it 'returns the name of the last lock acquired' do
      Tag.with_advisory_lock(lock_name) do
        Tag.current_advisory_lock.must_equal lock_name
      end
    end
  end

  describe '.advisory_lock_exists?' do
    it "returns false for an unacquired lock" do
      Tag.advisory_lock_exists?(lock_name).must_equal false
    end

    it 'returns the name of the last lock acquired' do
      Tag.with_advisory_lock(lock_name) do
        Tag.advisory_lock_exists?(lock_name).must_equal true
      end
    end
  end

end if test_lock_exists?
