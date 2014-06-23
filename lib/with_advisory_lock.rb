require 'with_advisory_lock/version'

module WithAdvisoryLock
  extend ActiveSupport::Autoload

  autoload :Concern
  autoload :Base
  autoload :DatabaseAdapterSupport
  autoload :Flock
  autoload :MySQL, 'with_advisory_lock/mysql'
  autoload :NestedAdvisoryLockError
  autoload :PostgreSQL, 'with_advisory_lock/postgresql'
end

ActiveSupport.on_load :active_record do
  ActiveRecord::Base.send :include, WithAdvisoryLock::Concern
end
