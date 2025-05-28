# frozen_string_literal: true

module WithAdvisoryLock
  # Result object that indicates whether a lock was acquired and the result of the block
  Result = Data.define(:lock_was_acquired, :result) do
    def initialize(lock_was_acquired:, result: nil)
      super
    end

    def lock_was_acquired?
      lock_was_acquired
    end
  end
end
