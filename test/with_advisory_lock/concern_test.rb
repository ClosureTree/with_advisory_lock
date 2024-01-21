# frozen_string_literal: true

require 'test_helper'

class WithAdvisoryLockConcernTest < GemTestCase
  test 'adds with_advisory_lock to ActiveRecord classes' do
    assert_respond_to(Tag, :with_advisory_lock)
  end

  test 'adds with_advisory_lock to ActiveRecord instances' do
    assert_respond_to(Label.new, :with_advisory_lock)
  end

  test 'adds advisory_lock_exists? to ActiveRecord classes' do
    assert_respond_to(Tag, :advisory_lock_exists?)
  end

  test 'adds advisory_lock_exists? to ActiveRecord instances' do
    assert_respond_to(Label.new, :advisory_lock_exists?)
  end
end

class ActiveRecordQueryCacheTest < GemTestCase
  test 'does not disable quary cache by default' do
    ActiveRecord::Base.expects(:uncached).never
    Tag.with_advisory_lock('lock') { Tag.first }
  end

  test 'can disable ActiveRecord query cache' do
    ActiveRecord::Base.expects(:uncached).once
    Tag.with_advisory_lock('a-lock', disable_query_cache: true) { Tag.first }
  end
end
