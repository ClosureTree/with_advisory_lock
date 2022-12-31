# frozen_string_literal: true

require 'test_helper'

describe 'lock nesting' do
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
    assert_empty(impl.lock_stack)
    Tag.with_advisory_lock('first') do
      assert_equal(%w[first], impl.lock_stack.map(&:name))
      # Even MySQL should be OK with this:
      Tag.with_advisory_lock('first') do
        assert_equal(%w[first], impl.lock_stack.map(&:name))
      end
      assert_equal(%w[first], impl.lock_stack.map(&:name))
    end
    assert_empty(impl.lock_stack)
  end

  it 'does not raise errors with MySQL < 5.7.5 when acquiring nested error force enabled' do
    skip unless [:mysql2].include?(env_db)
    impl = WithAdvisoryLock::Base.new(nil, nil, nil)
    assert_empty(impl.lock_stack)
    Tag.with_advisory_lock('first', force_nested_lock_support: true) do
      assert_equal(%w[first], impl.lock_stack.map(&:name))
      Tag.with_advisory_lock('second', force_nested_lock_support: true) do
        assert_equal(%w[first second], impl.lock_stack.map(&:name))
        Tag.with_advisory_lock('first', force_nested_lock_support: true) do
          # Shouldn't ask for another lock:
          assert_equal(%w[first second], impl.lock_stack.map(&:name))
          Tag.with_advisory_lock('second', force_nested_lock_support: true) do
            # Shouldn't ask for another lock:
            assert_equal(%w[first second], impl.lock_stack.map(&:name))
          end
        end
      end
      assert_equal(%w[first], impl.lock_stack.map(&:name))
    end
    assert_empty(impl.lock_stack)
  end

  it 'supports nested advisory locks with !MySQL 5.6' do
    skip if [:mysql2].include? env_db
    impl = WithAdvisoryLock::Base.new(nil, nil, nil)
    assert_empty(impl.lock_stack)
    Tag.with_advisory_lock('first') do
      assert_equal(%w[first], impl.lock_stack.map(&:name))
      Tag.with_advisory_lock('second') do
        assert_equal(%w[first second], impl.lock_stack.map(&:name))
        Tag.with_advisory_lock('first') do
          # Shouldn't ask for another lock:
          assert_equal(%w[first second], impl.lock_stack.map(&:name))
          Tag.with_advisory_lock('second') do
            # Shouldn't ask for another lock:
            assert_equal(%w[first second], impl.lock_stack.map(&:name))
          end
        end
      end
      assert_equal(%w[first], impl.lock_stack.map(&:name))
    end
    assert_empty(impl.lock_stack)
  end

  it 'raises with !MySQL 5.6 and nested error force disabled' do
    skip unless [:mysql2].include?(env_db)

    exc = assert_raises(WithAdvisoryLock::NestedAdvisoryLockError) do
      Tag.with_advisory_lock('first', force_nested_lock_support: false) do
        Tag.with_advisory_lock('second', force_nested_lock_support: false) do
        end
      end
    end

    assert_equal(%w[first], exc.lock_stack.map(&:name))
  end
end
