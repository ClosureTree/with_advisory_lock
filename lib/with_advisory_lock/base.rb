require 'zlib'

module WithAdvisoryLock
  class Result
    attr_reader :result

    def initialize(lock_was_acquired, result = false)
      @lock_was_acquired = lock_was_acquired
      @result = result
    end

    def lock_was_acquired?
      @lock_was_acquired
    end
  end

  FAILED_TO_LOCK = Result.new(false)

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
      # access doesn't need to be synchronized as it is only accessed by the current thread.
      Thread.current[:with_advisory_lock_stack] ||= []
    end
    delegate :lock_stack, to: 'self.class'

    def already_locked?
      lock_stack.include? lock_str
    end

    def with_advisory_lock_if_needed(&block)
      if already_locked?
        Result.new(true, yield)
      elsif timeout_seconds == 0
        yield_with_lock(&block)
      else
        yield_with_lock_and_timeout(&block)
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

    def yield_with_lock_and_timeout(&block)
      give_up_at = Time.now + @timeout_seconds if @timeout_seconds
      while @timeout_seconds.nil? || Time.now < give_up_at do
        r = yield_with_lock(&block)
        return r if r.lock_was_acquired?
        # Randomizing sleep time may help reduce contention.
        sleep(rand(0.05..0.15))
      end
      FAILED_TO_LOCK
    end

    def yield_with_lock
      if try_lock
        begin
          lock_stack.push(lock_str)
          result = block_given? ? yield : nil
          Result.new(true, result)
        ensure
          lock_stack.pop
          release_lock
        end
      else
        FAILED_TO_LOCK
      end
    end

    # Prevent AR from caching results improperly
    def unique_column_name
      "t#{SecureRandom.hex}"
    end
  end
end
