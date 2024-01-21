# frozen_string_literal: true

module WithAdvisoryLock
  class FailedToAcquireLock < StandardError
    def initialize(lock_name)
      super("Failed to acquire lock #{lock_name}")
    end
  end
end
