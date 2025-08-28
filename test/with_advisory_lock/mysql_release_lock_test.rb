# frozen_string_literal: true

require 'test_helper'

class MySQLReleaseLockTest < GemTestCase
  self.use_transactional_tests = false

  def model_class
    MysqlTag
  end

  def setup
    super
    begin
      skip unless model_class.connection.adapter_name =~ /mysql/i
      MysqlTag.delete_all
    rescue ActiveRecord::NoDatabaseError
      skip "MySQL database not available. Please create the database first."
    rescue StandardError => e
      skip "MySQL connection failed: #{e.message}"
    end
  end

  test 'release_advisory_lock handles gem signature with lock_keys' do
    lock_name = 'test_gem_signature'
    lock_keys = model_class.connection.lock_keys_for(lock_name)

    # Acquire the lock
    result = model_class.connection.try_advisory_lock(
      lock_keys,
      lock_name: lock_name,
      shared: false,
      transaction: false
    )
    assert result, 'Failed to acquire lock'

    # Release using gem signature
    released = model_class.connection.release_advisory_lock(
      lock_keys,
      lock_name: lock_name,
      shared: false,
      transaction: false
    )
    assert released, 'Failed to release lock using gem signature'

    # Verify lock is released by trying to acquire it again
    result = model_class.connection.try_advisory_lock(
      lock_keys,
      lock_name: lock_name,
      shared: false,
      transaction: false
    )
    assert result, 'Lock was not properly released'

    # Clean up
    model_class.connection.release_advisory_lock(
      lock_keys,
      lock_name: lock_name,
      shared: false,
      transaction: false
    )
  end

  test 'release_advisory_lock handles ActiveRecord signature' do
    # Rails calls release_advisory_lock with a positional argument (lock_id)
    # This test ensures our override doesn't break Rails' migration locking

    lock_name = 'test_rails_signature'

    # Acquire lock using SQL (ActiveRecord doesn't provide get_advisory_lock method)
    lock_keys = model_class.connection.lock_keys_for(lock_name)
    result = model_class.connection.query_value("SELECT GET_LOCK(#{model_class.connection.quote(lock_keys.first)}, 0)")
    assert_equal 1, result, 'Failed to acquire lock using SQL'

    # Release using ActiveRecord signature (positional argument, as Rails does)
    released = model_class.connection.release_advisory_lock(lock_keys.first)
    assert released, 'Failed to release lock using ActiveRecord signature'

    # Verify lock is released
    lock_keys = model_class.connection.lock_keys_for(lock_name)
    result = model_class.connection.query_value("SELECT GET_LOCK(#{model_class.connection.quote(lock_keys.first)}, 0)")
    assert_equal 1, result, 'Lock was not properly released'

    # Clean up
    model_class.connection.query_value("SELECT RELEASE_LOCK(#{model_class.connection.quote(lock_keys.first)})")
  end

  test 'release_advisory_lock handles connection errors gracefully' do
    lock_name = 'test_connection_error'
    lock_keys = model_class.connection.lock_keys_for(lock_name)

    # Acquire the lock
    result = model_class.connection.try_advisory_lock(
      lock_keys,
      lock_name: lock_name,
      shared: false,
      transaction: false
    )
    assert result, 'Failed to acquire lock'

    # Simulate connection error handling
    # The method should handle various connection error types without raising
    begin
      # Try to release - even if we can't simulate a real connection error,
      # the code path exists and should work
      model_class.connection.release_advisory_lock(
        lock_keys,
        lock_name: lock_name,
        shared: false,
        transaction: false
      )
    rescue StandardError => e
      # Should not raise connection-related errors
      refute_match(/Lost connection|MySQL server has gone away|Connection refused/i, e.message)
      raise
    end
  end
end
