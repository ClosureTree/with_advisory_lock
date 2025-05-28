# frozen_string_literal: true

module WithAdvisoryLock
  # Lock stack item to track acquired locks
  LockStackItem = Data.define(:name, :shared)
end
