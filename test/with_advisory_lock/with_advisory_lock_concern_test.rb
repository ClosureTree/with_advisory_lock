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
<<<<<<<< HEAD:test/with_advisory_lock/with_advisory_lock_concern_test.rb
========

class ActiveRecordQueryCacheTest < GemTestCase
  test 'does not disable quary cache by default' do
    Tag.connection.expects(:uncached).never
    Tag.with_advisory_lock('lock') { Tag.first }
  end

  test 'can disable ActiveRecord query cache' do
    Tag.connection.expects(:uncached).once
    Tag.with_advisory_lock('a-lock', disable_query_cache: true) { Tag.first }
  end
end
>>>>>>>> origin/master:test/with_advisory_lock/concern_test.rb
