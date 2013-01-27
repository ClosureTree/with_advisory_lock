require 'minitest_helper'

describe "simplest" do
  it "should prevent threads from accessing a resource concurrently" do
    times = ActiveSupport::OrderedHash.new
    ActiveRecord::Base.connection_pool.disconnect!
    t1 = Thread.new do
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.with_advisory_lock("simplest test") do
        times[:t1_acquire] = Time.now
        sleep 0.5
      end
      times[:t1_release] = Time.now
    end
    sleep 0.1
    t2 = Thread.new do
      ActiveRecord::Base.connection.reconnect!
      ActiveRecord::Base.with_advisory_lock("simplest test") do
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
end
