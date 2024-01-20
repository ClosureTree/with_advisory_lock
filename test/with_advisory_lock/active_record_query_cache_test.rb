# frozen_string_literal: true

require 'test_helper'
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
