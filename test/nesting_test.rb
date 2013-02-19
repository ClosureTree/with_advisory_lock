require 'minitest_helper'

describe "lock nesting" do
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
    skip if env_db != 'mysql'
    proc {
      Tag.with_advisory_lock("first") do
        Tag.with_advisory_lock("second") do
        end
      end
    }.must_raise WithAdvisoryLock::NestedAdvisoryLockError
  end

  it "supports nested advisory locks with !MySQL" do
    skip if env_db == 'mysql'
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
