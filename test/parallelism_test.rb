require 'minitest_helper'

describe "parallelism" do
  def find_or_create_at_even_second(run_at, with_advisory_lock)
    ActiveRecord::Base.connection.reconnect!
    sleep_time = run_at - Time.now.to_f
    $stderr.puts "sleeping for #{sleep_time} for #{run_at}"
    sleep(sleep_time)
    name = run_at.to_s
    task = lambda do
      Tag.transaction do
        Tag.find_by_name(name) || Tag.create(:name => name)
      end
      $stderr.puts "finished with #{run_at}"
    end
    if with_advisory_lock
      Tag.with_advisory_lock(name, nil, &task)
    else
      task.call
    end
  end

  def run_workers(with_advisory_lock)
    skip if env_db == "sqlite"
    start_time = Time.now.to_i + 2
    threads = @workers.times.collect do
      Thread.new do
        @iterations.times do |ea|
          find_or_create_at_even_second(start_time + ea, with_advisory_lock)
        end
      end
    end
    threads.each { |ea| ea.join }
    puts "Created #{Tag.all.size} (lock = #{with_advisory_lock})"
  end

  before :each do
    @iterations = 5
    @workers = 10
  end

  it "parallel threads create multiple duplicate rows" do
    run_workers(with_advisory_lock = false)
    if Tag.connection.adapter_name == "SQLite" && RUBY_VERSION == "1.9.3"
      oper = :== # sqlite doesn't run in parallel.
    else
      oper = :> # Everything else should create duplicate rows.
    end
    Tag.all.size.must_be oper, @iterations # <- any duplicated rows will make me happy.
    TagAudit.all.size.must_be oper, @iterations # <- any duplicated rows will make me happy.
    Label.all.size.must_be oper, @iterations # <- any duplicated rows will make me happy.
  end

  it "parallel threads with_advisory_lock don't create multiple duplicate rows" do
    run_workers(with_advisory_lock = true)
    Tag.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    TagAudit.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    Label.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
  end

  it "returns false if the lock wasn't acquirable" do
    t1_acquired_lock = false
    t1_return_value = nil
    t1 = Thread.new do
      ActiveRecord::Base.connection.reconnect!
      t1_return_value = Label.with_advisory_lock("testing 1,2,3") do
        t1_acquired_lock = true
        sleep(0.3)
        "boom"
      end
    end

    # Make sure the lock is acquired:
    sleep(0.1)

    # Now try to acquire the lock impatiently:
    t2_acquired_lock = false
    t2_return_value = nil
    t2 = Thread.new do
      ActiveRecord::Base.connection.reconnect!
      t2_return_value = Label.with_advisory_lock("testing 1,2,3", 0.1) do
        t2_acquired_lock = true
        "not expected"
      end
    end

    # Wait for them to finish:
    t1.join
    t2.join

    t1_acquired_lock.must_be_true
    t1_return_value.must_equal "boom"

    t2_acquired_lock.must_be_false
    t2_return_value.must_be_false
  end
end
