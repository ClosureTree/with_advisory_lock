# frozen_string_literal: true

require 'with_advisory_lock/version'

require 'active_support'

module WithAdvisoryLock
  autoload :Concern, 'with_advisory_lock/concern'
  autoload :Result, 'with_advisory_lock/result'
  autoload :LockStackItem, 'with_advisory_lock/lock_stack_item'

  # Modules for adapter injection
  autoload :CoreAdvisory, 'with_advisory_lock/core_advisory'
  autoload :PostgreSQLAdvisory, 'with_advisory_lock/postgresql_advisory'
  autoload :MySQLAdvisory, 'with_advisory_lock/mysql_advisory'

  autoload :FailedToAcquireLock, 'with_advisory_lock/failed_to_acquire_lock'
end

ActiveSupport.on_load :active_record do
  require 'active_record/connection_adapters/abstract_adapter'
  ActiveRecord::Base.include WithAdvisoryLock::Concern
  puts '[WithAdvisoryLock] Loaded into ActiveRecord' if ENV['DEBUG_LOAD']
end

# JRuby compatibility handling
if RUBY_ENGINE == 'jruby'
  require 'with_advisory_lock/jruby_adapter'
  WithAdvisoryLock::JRubyAdapter.install!
  # Don't set up the standard hooks for JRuby
else
  # Standard adapter injection for MRI and TruffleRuby
  ActiveSupport.on_load :active_record_postgresqladapter do
    puts '[WithAdvisoryLock] Loading into :active_record_postgresqladapter hook' if ENV['DEBUG_LOAD']
    prepend WithAdvisoryLock::CoreAdvisory
    prepend WithAdvisoryLock::PostgreSQLAdvisory
  end

  ActiveSupport.on_load :active_record_mysql2adapter do
    puts '[WithAdvisoryLock] Loading into :active_record_mysql2adapter hook' if ENV['DEBUG_LOAD']
    prepend WithAdvisoryLock::CoreAdvisory
    prepend WithAdvisoryLock::MySQLAdvisory
  end

  ActiveSupport.on_load :active_record_trilogyadapter do
    puts '[WithAdvisoryLock] Loading into :active_record_trilogyadapter hook' if ENV['DEBUG_LOAD']
    prepend WithAdvisoryLock::CoreAdvisory
    prepend WithAdvisoryLock::MySQLAdvisory
  end
end
