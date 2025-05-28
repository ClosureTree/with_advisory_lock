# frozen_string_literal: true

require 'test_helper'

module ConcernTestCases
  extend ActiveSupport::Concern

  included do
    test 'adds with_advisory_lock to ActiveRecord classes' do
      assert_respond_to(model_class, :with_advisory_lock)
    end

    test 'adds with_advisory_lock to ActiveRecord instances' do
      assert_respond_to(model_class.new, :with_advisory_lock)
    end

    test 'adds advisory_lock_exists? to ActiveRecord classes' do
      assert_respond_to(model_class, :advisory_lock_exists?)
    end

    test 'adds advisory_lock_exists? to ActiveRecord instances' do
      assert_respond_to(model_class.new, :advisory_lock_exists?)
    end
  end
end

class PostgreSQLConcernTest < GemTestCase
  include ConcernTestCases

  def model_class
    Tag
  end
end

class MySQLConcernTest < GemTestCase
  include ConcernTestCases

  def model_class
    MysqlTag
  end
end

# This test is adapter-agnostic, so we only need to test it once
class ActiveRecordQueryCacheTest < GemTestCase
  self.use_transactional_tests = false

  test 'does not disable quary cache by default' do
    Tag.connection.expects(:uncached).never
    Tag.with_advisory_lock('lock') { Tag.first }
  end

  test 'can disable ActiveRecord query cache' do
    # Mocha expects needs to properly handle block return values
    connection = Tag.connection

    # Create a stub that properly yields and returns the block's result
    connection.define_singleton_method(:uncached_with_mock) do |&block|
      @uncached_called = true
      uncached_without_mock(&block)
    end

    connection.define_singleton_method(:uncached_called?) do
      @uncached_called || false
    end

    connection.singleton_class.alias_method :uncached_without_mock, :uncached
    connection.singleton_class.alias_method :uncached, :uncached_with_mock

    begin
      Tag.with_advisory_lock('a-lock', disable_query_cache: true) { Tag.first }
      assert connection.uncached_called?, 'uncached should have been called'
    ensure
      connection.singleton_class.alias_method :uncached, :uncached_without_mock
      connection.singleton_class.remove_method :uncached_with_mock
      connection.singleton_class.remove_method :uncached_without_mock
      connection.singleton_class.remove_method :uncached_called?
    end
  end
end
