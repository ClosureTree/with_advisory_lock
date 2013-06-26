require 'minitest_helper'

describe "prevents threads from accessing a resource concurrently" do
  def assert_correct_parallel_behavior(lock_name)
    times = ActiveSupport::OrderedHash.new
    ActiveRecord::Base.connection_pool.disconnect!
    t1 = Thread.new do
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.with_advisory_lock(lock_name) do
        times[:t1_acquire] = Time.now
        sleep 0.5
      end
      times[:t1_release] = Time.now
    end
    sleep 0.1
    t2 = Thread.new do
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.with_advisory_lock(lock_name) do
        times[:t2_acquire] = Time.now
        sleep 1
      end
      times[:t2_release] = Time.now
    end
    t1.join
    t2.join
    times.keys.must_equal [:t1_acquire, :t1_release, :t2_acquire, :t2_release]
    times[:t2_acquire].must_be :>, times[:t1_release]
  end

  it "with a string lock name" do
    assert_correct_parallel_behavior("example lock name")
  end

  it "with a numeric lock name" do
    assert_correct_parallel_behavior(1234)
  end
end
