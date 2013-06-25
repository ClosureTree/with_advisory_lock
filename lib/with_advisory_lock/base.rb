module WithAdvisoryLock
  class Base
    attr_reader :connection, :lock_name, :timeout_seconds

    def initialize(connection, lock_name, timeout_seconds)
      @connection = connection
      @lock_name = ENV['WITH_ADVISORY_LOCK_PREFIX'].to_s + lock_name
      @timeout_seconds = timeout_seconds
    end

    def quoted_lock_name
      connection.quote(lock_name)
    end

    def lock_stack
      Thread.current[:with_advisory_lock_stack] ||= []
    end

    def already_locked?
      lock_stack.include? @lock_name
    end

    def with_advisory_lock_if_needed
      if already_locked?
        yield
      else
        yield_with_lock { yield }
      end
    end

    def yield_with_lock
      give_up_at = Time.now + @timeout_seconds if @timeout_seconds
      while @timeout_seconds.nil? || Time.now < give_up_at do
        if try_lock
          begin
            lock_stack.push(lock_name)
            return yield
          ensure
            lock_stack.pop
            release_lock
          end
        else
          # sleep between 1/20 and ~1/5 of a second.
          # Randomizing sleep time may help reduce contention.
          sleep(rand * 0.15 + 0.05)
        end
      end
      false # failed to get lock in time.
    end
  end
end
