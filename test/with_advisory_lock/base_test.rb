require 'test_helper'

class WithAdvisoryLockBaseTest < GemTestCase
  test 'should support advisory_locks_enabled' do
    assert Tag.connection.advisory_locks_enabled?
  end
end
