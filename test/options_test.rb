# frozen_string_literal: true

require 'minitest_helper'

describe 'options parsing' do
  def parse_options(options)
    WithAdvisoryLock::Base.new(mock, mock, options)
  end

  specify 'defaults (empty hash)' do
    impl = parse_options({})
    assert_nil(impl.timeout_seconds)
    refute(impl.shared)
    refute(impl.transaction)
  end

  specify 'nil sets timeout to nil' do
    impl = parse_options(nil)
    assert_nil(impl.timeout_seconds)
    refute(impl.shared)
    refute(impl.transaction)
  end

  specify 'integer sets timeout to value' do
    impl = parse_options(42)
    assert_equal(42, impl.timeout_seconds)
    refute(impl.shared)
    refute(impl.transaction)
  end

  specify 'hash with invalid key errors' do
    assert_raises(ArgumentError) do
      parse_options(foo: 42)
    end
  end

  specify 'hash with timeout_seconds sets timeout to value' do
    impl = parse_options(timeout_seconds: 123)
    assert_equal(123, impl.timeout_seconds)
    refute(impl.shared)
    refute(impl.transaction)
  end

  specify 'hash with shared option sets shared to true' do
    impl = parse_options(shared: true)
    assert_nil(impl.timeout_seconds)
    assert(impl.shared)
    refute(impl.transaction)
  end

  specify 'hash with transaction option set transaction to true' do
    impl = parse_options(transaction: true)
    assert_nil(impl.timeout_seconds)
    refute(impl.shared)
    assert(impl.transaction)
  end

  specify 'hash with multiple keys sets options' do
    foo = mock
    bar = mock
    impl = parse_options(timeout_seconds: foo, shared: bar)
    assert_equal(foo, impl.timeout_seconds)
    assert_equal(bar, impl.shared)
    refute(impl.transaction)
  end
end
