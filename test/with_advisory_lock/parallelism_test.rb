# frozen_string_literal: true

require 'test_helper'
require 'forwardable'

class FindOrCreateWorker
extend Forwardable
def_delegators :@thread, :join, :wakeup, :status, :to_s

def initialize(name, use_advisory_lock)
  @name = name
  @use_advisory_lock = use_advisory_lock
  @thread = Thread.new { work_later }
end

def work_later
  sleep
  ApplicationRecord.connection_pool.with_connection do
    if @use_advisory_lock
      Tag.with_advisory_lock(@name) { work }
    else
      work
    end
  end
end

def work
  Tag.transaction do
    Tag.where(name: @name).first_or_create
  end
end
end

class ParallelismTest < GemTestCase
  def run_workers
    @names = @iterations.times.map { |iter| "iteration ##{iter}" }
    @names.each do |name|
      workers = @workers.times.map do
        FindOrCreateWorker.new(name, @use_advisory_lock)
      end
      # Wait for all the threads to get ready:
      sleep(0.1) until workers.all? { |ea| ea.status == 'sleep' }
      # OK, GO!
      workers.each(&:wakeup)
      # Then wait for them to finish:
      workers.each(&:join)
    end
    # Ensure we're still connected:
    ApplicationRecord.connection_pool.connection
  end

  setup do
    ApplicationRecord.connection.reconnect!
    @workers = 10
  end

  test 'creates multiple duplicate rows without advisory locks' do
    skip if %i[sqlite3 jdbcsqlite3].include?(env_db)
    erererere
    @use_advisory_lock = false
    @iterations = 1
    run_workers
    assert_operator(Tag.all.size,      :>, @iterations) # <- any duplicated rows will make me happy.
    assert_operator(TagAudit.all.size, :>, @iterations) # <- any duplicated rows will make me happy.
    assert_operator(Label.all.size,    :>, @iterations) # <- any duplicated rows will make me happy.
  end

  test "doesn't create multiple duplicate rows with advisory locks" do
    @use_advisory_lock = true
    @iterations = 10
    run_workers
    assert_equal(@iterations, Tag.all.size)       # <- any duplicated rows will NOT make me happy.
    assert_equal(@iterations, TagAudit.all.size)  # <- any duplicated rows will NOT make me happy.
    assert_equal(@iterations, Label.all.size)     # <- any duplicated rows will NOT make me happy.
  end
end
