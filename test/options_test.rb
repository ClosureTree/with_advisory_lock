require 'minitest_helper'

describe 'options parsing' do
  def parse_options(options)
    WithAdvisoryLock::Base.new(mock, mock, options)
  end

  specify 'defaults (empty hash)' do
    impl = parse_options({})
    impl.timeout_seconds.must_equal nil
  end

  specify 'nil sets timeout to nil' do
    impl = parse_options(nil)
    impl.timeout_seconds.must_equal nil
  end

  specify 'integer sets timeout to value' do
    impl = parse_options(42)
    impl.timeout_seconds.must_equal 42
  end

  specify 'hash with invalid key errors' do
    proc {
      parse_options(foo: 42)
    }.must_raise ArgumentError
  end

  specify 'hash with timeout_seconds sets timeout to value' do
    impl = parse_options(timeout_seconds: 123)
    impl.timeout_seconds.must_equal 123
  end
end
