require 'test_helper'

class WithAdvisoryLockBaseTest < GemTestCase
  test 'should support advisory_locks_enabled' do
    assert Tag.connection.advisory_locks_enabled?
  end

  test 'should support advisory_locks_enabled for mysql' do
    assert MysqlRecord.connection.advisory_locks_enabled?
  end
end
