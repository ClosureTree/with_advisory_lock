require 'zlib'

module WithAdvisoryLock
  class Base
    attr_reader :connection, :lock_name, :timeout_seconds

    def initialize(connection, lock_name, timeout_seconds)
      @connection = connection
      @lock_name = lock_name
      lock_name_prefix = ENV['WITH_ADVISORY_LOCK_PREFIX']
      if lock_name_prefix
        @lock_name = if lock_name.is_a? Numeric
          "#{lock_name_prefix.to_i}#{lock_name}".to_i
        else
          "#{lock_name_prefix}#{lock_name}"
        end
      end
      @timeout_seconds = timeout_seconds
    end

    def quoted_lock_name
      connection.quote(lock_name)
    end

    def self.lock_stack
      Thread.current[:with_advisory_lock_stack] ||= []
    end

    delegate :lock_stack, to: 'self.class'

    def already_locked?
      lock_stack.include? @lock_name
    end

    def advisory_lock_exists?(name)
      raise NoMethodError, "method must be implemented in implementation subclasses"
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

    def yield_with_lock
      give_up_at = Time.now + @timeout_seconds if @timeout_seconds
      begin
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
      end while @timeout_seconds.nil? || Time.now < give_up_at
      false # failed to get lock in time.
    end
  end
end
