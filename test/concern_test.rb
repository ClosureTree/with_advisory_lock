# frozen_string_literal: true

require 'test_helper'

describe 'with_advisory_lock.concern' do
  it 'adds with_advisory_lock to ActiveRecord classes' do
    assert_respond_to(Tag, :with_advisory_lock)
  end

  it 'adds with_advisory_lock to ActiveRecord instances' do
    assert_respond_to(Label.new, :with_advisory_lock)
  end

  it 'adds advisory_lock_exists? to ActiveRecord classes' do
    assert_respond_to(Tag, :advisory_lock_exists?)
  end

  it 'adds advisory_lock_exists? to ActiveRecord classes' do
    assert_respond_to(Label.new, :advisory_lock_exists?)
  end
end

describe 'ActiveRecord query cache' do
  it 'does not disable quary cache by default' do
    ActiveRecord::Base.expects(:uncached).never

    Tag.with_advisory_lock('lock') { Tag.first }
  end

  it 'can disable ActiveRecord query cache' do
    ActiveRecord::Base.expects(:uncached).once

    Tag.with_advisory_lock('a-lock', disable_query_cache: true) { Tag.first }
  end
end
