require 'minitest_helper'

describe "lock nesting" do
  it "warns about MySQL releasing advisory locks" do
    Tag.expects(:wal_log)
    Tag.with_advisory_lock("first") do
      Tag.with_advisory_lock("second") do
      end
    end
  end
end if env_db == 'mysql'
