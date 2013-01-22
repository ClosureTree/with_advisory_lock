module WithAdvisoryLock
  class Base
    attr_reader :connection, :lock_name, :timeout_seconds

    def initialize(connection, lock_name, timeout_seconds)
      @connection = connection
      @lock_name = lock_name
      @timeout_seconds = timeout_seconds
    end

    def quoted_lock_name
      connection.quote(lock_name)
    end

    def with_advisory_lock(&block)
      give_up_at = Time.now + @timeout_seconds if @timeout_seconds
      while @timeout_seconds.nil? || Time.now < give_up_at do
        if try_lock
          begin
            return yield
          ensure
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