require 'minitest_helper'

describe "with_advisory_lock" do
  it "adds with_advisory_lock to ActiveRecord classes" do
    assert Tag.respond_to?(:with_advisory_lock)
  end

  it "adds with_advisory_lock to ActiveRecord instances" do
    assert Tag.new.respond_to?(:with_advisory_lock)
  end

  def find_or_create_at_even_second(run_at, with_advisory_lock)
    sleep(run_at - Time.now.to_f)
    name = run_at.to_s
    if with_advisory_lock
      Tag.with_advisory_lock(name) do
        Tag.find_by_name(name) || Tag.create!(:name => name)
      end
    else
      Tag.find_by_name(name) || Tag.create!(:name => name)
    end
  end

  def run_workers(with_advisory_lock)
    start_time = Time.now.to_i + 2
    threads = @workers.times.collect do
      Thread.new do
        begin
          ActiveRecord::Base.connection.reconnect!
          @iterations.times do |ea|
            find_or_create_at_even_second(start_time + (ea * 2), with_advisory_lock)
          end
        ensure
          ActiveRecord::Base.connection.close
        end
      end
    end
    threads.each { |ea| ea.join }
    puts "Created #{Tag.all.size} (lock = #{with_advisory_lock})"
  end

  before :each do
    @iterations = 5
    @workers = 7
  end

  it "parallel threads create multiple duplicate rows" do
    run_workers(with_advisory_lock = false)
    if Tag.connection.adapter_name == "SQLite" && RUBY_VERSION == "1.9.3"
      Tag.all.size.must_equal @iterations # <- sqlite on 1.9.3 doesn't create dupes IKNOWNOTWHY
    else
      Tag.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
      TagAudit.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
      Label.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
    end
  end

  it "parallel threads with_advisory_lock don't create multiple duplicate rows" do
    run_workers(with_advisory_lock = true)
    Tag.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    TagAudit.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    Label.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
  end
end
