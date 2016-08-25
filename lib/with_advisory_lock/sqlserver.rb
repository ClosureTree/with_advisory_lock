module WithAdvisoryLock
  class SQLServer < Base
    # See https://msdn.microsoft.com/en-us/library/ms189823.aspx
    def try_lock
      execute_successful?(sp_function: :sp_getapplock, lock_owner: 'Session', lock_mode: 'Exclusive')
    end

    def release_lock
      if connection.open_transactions <= 0
        execute_successful?(sp_function: :sp_releaseapplock, lock_owner: 'Session')
      end
    end

    def execute_successful?(sp_function:, lock_owner:, lock_mode: nil)
      case sp_function
      when :sp_getapplock
        connection.execute_procedure(sp_function, @lock_name, lock_mode, lock_owner, @timeout_seconds)
      when :sp_releaseapplock
        connection.execute_procedure(sp_function, @lock_name, lock_owner)
      end
      connection.raw_connection.return_code == 0
    end
  end
end

