# frozen_string_literal: true

require 'test_helper'

class LockNestingTest < GemTestCase
  setup do
    @prior_prefix = ENV['WITH_ADVISORY_LOCK_PREFIX']
    ENV['WITH_ADVISORY_LOCK_PREFIX'] = nil
  end

  teardown do
    ENV['WITH_ADVISORY_LOCK_PREFIX'] = @prior_prefix
  end

  test "doesn't request the same lock twice" do
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
end
