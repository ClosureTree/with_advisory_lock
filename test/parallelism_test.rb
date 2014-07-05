require 'minitest_helper'

describe "parallelism" do
  class WorkerBase
    def initialize(target, run_at, name, use_advisory_lock)
      @thread = Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          before_work
          sleep((run_at - Time.now).to_f)
          if use_advisory_lock
            Tag.with_advisory_lock(name) { work(name) }
          else
            work(name)
          end
        end
      end
    end

    def before_work
    end

    def work(name)
      raise
    end

    def join
      @thread.join
    end
  end

  class FindOrCreateWorker < WorkerBase
    def work(name)
      Tag.transaction do
        Tag.where(name: name).first_or_create
      end
    end
  end

  def run_workers(use_advisory_lock, worker_class = FindOrCreateWorker)
    all_workers = []
    @names = @iterations.times.map { |iter| "iteration ##{iter}" }
    @names.each do |name|
      wake_time = 1.second.from_now
      workers = @workers.times.map do
        worker_class.new(@target, wake_time, name, use_advisory_lock)
      end
      workers.each(&:join)
      all_workers += workers
      puts name
    end
    # Ensure we're still connected:
    ActiveRecord::Base.connection_pool.connection
    all_workers
  end

  before :each do
    ActiveRecord::Base.connection.reconnect!
    @iterations = 5
    @workers = 10
  end

  it "creates multiple duplicate rows without advisory locks" do
    run_workers(use_advisory_lock = false)
    Tag.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
    TagAudit.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
    Label.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
  end unless env_db == :sqlite

  it "doesn't create multiple duplicate rows with advisory locks" do
    run_workers(use_advisory_lock = true)
    Tag.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    TagAudit.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    Label.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
  end

  it "returns false if the lock wasn't acquirable" do
    t1_acquired_lock = false
    t1_return_value = nil
    lock_name = "testing 1,2,3"

    t1 = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        t1_return_value = Label.with_advisory_lock(lock_name) do
          t1_acquired_lock = true
          sleep(0.5)
          't1 finished'
        end
      end
    end

    sleep(0.1)
    ActiveRecord::Base.connection.reconnect!
    Label.with_advisory_lock(lock_name, 0) do
      fail "lock should not be acquirable at this point"
    end

    t1.join
    t1_return_value.must_equal 't1 finished'
    ActiveRecord::Base.connection.reconnect!
    # We should now be able to acquire the lock immediately:
    reacquired = false
    Label.with_advisory_lock(lock_name, 0) do
      reacquired = true
    end.must_be_true
    reacquired.must_be_true
  end
end
