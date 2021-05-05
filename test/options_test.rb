require 'minitest_helper'

describe 'options parsing' do
  def parse_options(options)
    WithAdvisoryLock::Base.new(mock, mock, options)
  end

  specify 'defaults (empty hash)' do
    impl = parse_options({})
    _(impl.timeout_seconds).must_be_nil
    _(impl.shared).must_equal false
    _(impl.transaction).must_equal false
  end

  specify 'nil sets timeout to nil' do
    impl = parse_options(nil)
    _(impl.timeout_seconds).must_be_nil
    _(impl.shared).must_equal false
    _(impl.transaction).must_equal false
  end

  specify 'integer sets timeout to value' do
    impl = parse_options(42)
    _(impl.timeout_seconds).must_equal 42
    _(impl.shared).must_equal false
    _(impl.transaction).must_equal false
  end

  specify 'hash with invalid key errors' do
    _(proc {
      parse_options(foo: 42)
    }).must_raise ArgumentError
  end

  specify 'hash with timeout_seconds sets timeout to value' do
    impl = parse_options(timeout_seconds: 123)
    _(impl.timeout_seconds).must_equal 123
    _(impl.shared).must_equal false
    _(impl.transaction).must_equal false
  end

  specify 'hash with shared option sets shared to true' do
    impl = parse_options(shared: true)
    _(impl.timeout_seconds).must_be_nil
    _(impl.shared).must_equal true
    _(impl.transaction).must_equal false
  end

  specify 'hash with transaction option set transaction to true' do
    impl = parse_options(transaction: true)
    _(impl.timeout_seconds).must_be_nil
    _(impl.shared).must_equal false
    _(impl.transaction).must_equal true
  end

  specify 'hash with multiple keys sets options' do
    foo = mock
    bar = mock
    impl = parse_options(timeout_seconds: foo, shared: bar)
    _(impl.timeout_seconds).must_equal foo
    _(impl.shared).must_equal bar
    _(impl.transaction).must_equal false
  end
end
