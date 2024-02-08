# frozen_string_literal: true

require 'test_helper'

class OptionsParsingTest < GemTestCase
  def parse_options(options)
    WithAdvisoryLock::Base.new(mock, mock, options)
  end

  test 'defaults (empty hash)' do
    impl = parse_options({})
    assert_nil(impl.timeout_seconds)
    assert_not(impl.shared)
    assert_not(impl.transaction)
  end

  test 'nil sets timeout to nil' do
    impl = parse_options(nil)
    assert_nil(impl.timeout_seconds)
    assert_not(impl.shared)
    assert_not(impl.transaction)
  end

  test 'integer sets timeout to value' do
    impl = parse_options(42)
    assert_equal(42, impl.timeout_seconds)
    assert_not(impl.shared)
    assert_not(impl.transaction)
  end

  test 'hash with invalid key errors' do
    assert_raises(ArgumentError) do
      parse_options(foo: 42)
    end
  end

  test 'hash with timeout_seconds sets timeout to value' do
    impl = parse_options(timeout_seconds: 123)
    assert_equal(123, impl.timeout_seconds)
    assert_not(impl.shared)
    assert_not(impl.transaction)
  end

  test 'hash with shared option sets shared to true' do
    impl = parse_options(shared: true)
    assert_nil(impl.timeout_seconds)
    assert(impl.shared)
    assert_not(impl.transaction)
  end

  test 'hash with transaction option set transaction to true' do
    impl = parse_options(transaction: true)
    assert_nil(impl.timeout_seconds)
    assert_not(impl.shared)
    assert(impl.transaction)
  end

  test 'hash with multiple keys sets options' do
    foo = mock
    bar = mock
    impl = parse_options(timeout_seconds: foo, shared: bar)
    assert_equal(foo, impl.timeout_seconds)
    assert_equal(bar, impl.shared)
    assert_not(impl.transaction)
  end
end
