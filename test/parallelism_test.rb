require 'minitest_helper'

describe 'parallelism' do
  class FindOrCreateWorker
    attr_reader :sleep_time

    def initialize(run_at, name, use_advisory_lock)
      @run_at = run_at
      @name = name
      @use_advisory_lock = use_advisory_lock
      @thread = Thread.new { work_later }
    end

    def work_later
      ActiveRecord::Base.connection_pool.with_connection do
        @sleep_time = @run_at - Time.now.to_f
        puts "#{self} sleeping for #{sleep_time}"
        fail "ack, negative sleep time!" if sleep_time <= 0
        sleep(sleep_time)
        puts "YAY #{self} WOKE UP"
        if @use_advisory_lock
          Tag.with_advisory_lock(@name) { work }
        else
          work
        end
        puts "YAY #{self} FINISHED"
      end
    end

    def work
      puts "YAY #{self} STARTED WORK"
      Tag.transaction do
        puts "YAY #{self} IS IN TRANSACTION"
        Tag.where(name: @name).first_or_create
        puts "YAY #{self} DID FIRST OR CREATE"
      end
      puts "YAY #{self} FINISHED WORK"
    end

    def join(time = 0.1)
      @thread.join(time)
    end

    def to_s
      @thread.to_s
    end
  end

  def run_workers
    all_workers = []
    @names = @iterations.times.map { |iter| "iteration ##{iter}" }
    @names.each do |name|
      wake_time = Time.now.to_f + 0.7
      workers = @workers.times.map do
        puts "making new worker that will wake up at #{wake_time}..."
        FindOrCreateWorker.new(wake_time, name, @use_advisory_lock)
      end
      all_workers += workers
      while workers.present?
        puts "asking #{workers} to finish..."
        workers.delete_if { |w| w.join }
      end
    end
    # Ensure we're still connected:
    ActiveRecord::Base.connection_pool.connection
    all_workers
  end

  before :each do
    ActiveRecord::Base.connection.reconnect!
    @workers = 10
  end

  it 'creates multiple duplicate rows without advisory locks' do
    @use_advisory_lock = false
    @iterations = 1
    run_workers
    Tag.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
    TagAudit.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
    Label.all.size.must_be :>, @iterations # <- any duplicated rows will make me happy.
  end unless env_db == :sqlite

  it "doesn't create multiple duplicate rows with advisory locks" do
    @use_advisory_lock = true
    @iterations = 10
    run_workers
    Tag.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    TagAudit.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
    Label.all.size.must_equal @iterations # <- any duplicated rows will NOT make me happy.
  end
end

describe 'separate thread tests' do
  let(:lock_name) { 'testing 1,2,3' }

  before do
    @t1_acquired_lock = false
    @t1_return_value = nil

    puts "starting new thread"
    @t1 = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        @t1_return_value = Label.with_advisory_lock(lock_name) do
          puts "new thread has lock"
          @t1_acquired_lock = true
          sleep(2)
          't1 finished'
          puts "new thread finished sleeping"
        end
      end
      puts "new thread finished"
    end

    # Wait for the thread to acquire the lock:
    sleep(1)
    ActiveRecord::Base.connection.reconnect!
  end

  after do
    @t1.join
  end

  it '#with_advisory_lock with a 0 timeout returns false immediately' do
    response = Label.with_advisory_lock(lock_name, 0) {}
    response.must_be_false
  end

  it '#with_advisory_lock yields to the provided block' do
    @t1_acquired_lock.must_be_true
  end

  it '#advisory_lock_exists? returns true when another thread has the lock' do
    Tag.advisory_lock_exists?(lock_name).must_be_true
  end

  it 'can re-establish the lock after the other thread releases it' do
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
