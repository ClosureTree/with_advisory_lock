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
          sleep(0.1)
        end
      end
      false # failed to get lock in time.
    end
  end
end