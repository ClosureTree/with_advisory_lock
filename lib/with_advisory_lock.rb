require 'with_advisory_lock/version'
require 'active_support'
require_relative 'with_advisory_lock/failed_to_acquire_lock'

module WithAdvisoryLock
  extend ActiveSupport::Autoload

  autoload :Concern
  autoload :Base
  autoload :DatabaseAdapterSupport
  autoload :Flock
  autoload :MySQL, 'with_advisory_lock/mysql'
  autoload :PostgreSQL, 'with_advisory_lock/postgresql'
end

ActiveSupport.on_load :active_record do
  include WithAdvisoryLock::Concern
end
