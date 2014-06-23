require 'minitest_helper'

describe "lock nesting" do
  # This simplifies what we expect from the lock name:
  before :each do
    @prior_prefix = ENV['WITH_ADVISORY_LOCK_PREFIX']
    ENV['WITH_ADVISORY_LOCK_PREFIX'] = nil
  end

  after :each do
    ENV['WITH_ADVISORY_LOCK_PREFIX'] = @prior_prefix
  end

  it "doesn't request the same lock twice" do
    impl = WithAdvisoryLock::Base.new(nil, nil, nil)
    impl.lock_stack.must_be_empty
    Tag.with_advisory_lock("first") do
      impl.lock_stack.must_equal %w(first)
      # Even MySQL should be OK with this:
      Tag.with_advisory_lock("first") do
        impl.lock_stack.must_equal %w(first)
      end
      impl.lock_stack.must_equal %w(first)
    end
    impl.lock_stack.must_be_empty
  end

  it "raises errors with MySQL when acquiring nested lock" do
    skip unless env_db == :mysql
    exc = proc {
      Tag.with_advisory_lock("first") do
        Tag.with_advisory_lock("second") do
        end
      end
    }.must_raise WithAdvisoryLock::NestedAdvisoryLockError
    exc.lock_stack.must_equal %w(first)
  end

  it "supports nested advisory locks with !MySQL" do
    skip if env_db == :mysql
    impl = WithAdvisoryLock::Base.new(nil, nil, nil)
    impl.lock_stack.must_be_empty
    Tag.with_advisory_lock("first") do
      impl.lock_stack.must_equal %w(first)
      Tag.with_advisory_lock("second") do
        impl.lock_stack.must_equal %w(first second)
        Tag.with_advisory_lock("first") do
          # Shouldn't ask for another lock:
          impl.lock_stack.must_equal %w(first second)
          Tag.with_advisory_lock("second") do
            # Shouldn't ask for another lock:
            impl.lock_stack.must_equal %w(first second)
          end
        end
      end
      impl.lock_stack.must_equal %w(first)
    end
    impl.lock_stack.must_be_empty
  end
end
