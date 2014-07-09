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
end

describe "separate thread tests" do
  let(:lock_name) { "testing 1,2,3" }

  before do
    @t1_acquired_lock = false
    @t1_return_value = nil

    @t1 = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        @t1_return_value = Label.with_advisory_lock(lock_name) do
          t1_acquired_lock = true
          sleep(0.4)
          't1 finished'
        end
      end
    end

    # Wait for the thread to acquire the lock:
    sleep(0.1)
    ActiveRecord::Base.connection.reconnect!
  end

  after do
    @t1.join
  end

  it "#with_advisory_lock with a 0 timeout returns false immediately" do
    response = Label.with_advisory_lock(lock_name, 0) {}
    response.must_be_false
  end

  it "#advisory_lock_exists? returns true when another thread has the lock" do
    Tag.advisory_lock_exists?(lock_name).must_be_true
  end

  it "can re-establish the lock after the other thread releases it" do
    @t1.join
    @t1_return_value.must_equal 't1 finished'

    # We should now be able to acquire the lock immediately:
    reacquired = false
    Label.with_advisory_lock(lock_name, 0) do
      reacquired = true
    end.must_be_true
    reacquired.must_be_true
  end
end
