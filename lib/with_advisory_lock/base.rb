require 'zlib'

module WithAdvisoryLock
  class Base
    attr_reader :connection, :lock_name, :timeout_seconds

    def initialize(connection, lock_name, timeout_seconds)
      @connection = connection
      @lock_name = lock_name
      @timeout_seconds = timeout_seconds
    end

    def lock_str
      @lock_str ||= "#{ENV['WITH_ADVISORY_LOCK_PREFIX'].to_s}#{lock_name.to_s}"
    end

    def self.lock_stack
      Thread.current[:with_advisory_lock_stack] ||= []
    end

    delegate :lock_stack, to: 'self.class'

    def already_locked?
      lock_stack.include? lock_str
    end

    def with_advisory_lock_if_needed
      if already_locked?
        yield
      else
        yield_with_lock { yield }
      end
    end

    def stable_hashcode(input)
      if input.is_a? Numeric
        input.to_i
      else
        # Ruby MRI's String#hash is randomly seeded as of Ruby 1.9 so
        # make sure we use a deterministic hash.
        Zlib.crc32(input.to_s)
      end
    end

    def advisory_lock_exists?
      acquired_lock = try_lock
    ensure
      release_lock if acquired_lock
    end

    def yield_with_lock
      give_up_at = Time.now + @timeout_seconds if @timeout_seconds
      begin
        if try_lock
          begin
            lock_stack.push(lock_str)
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
      end while @timeout_seconds.nil? || Time.now < give_up_at
      false # failed to get lock in time.
    end

    # The timestamp prevents AR from caching the result improperly, and is ignored.
    def query_cache_buster
      "AS t#{(Time.now.to_f * 1000).to_i}"
    end
  end
end
