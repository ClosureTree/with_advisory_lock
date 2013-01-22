require 'minitest_helper'

describe "with_advisory_lock.concern" do
  it "adds with_advisory_lock to ActiveRecord classes" do
    assert Tag.respond_to?(:with_advisory_lock)
  end

  it "adds with_advisory_lock to ActiveRecord instances" do
    assert Tag.new.respond_to?(:with_advisory_lock)
  end
end
