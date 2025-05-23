# frozen_string_literal: true

require 'with_advisory_lock/version'
require 'active_support'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'mysql' => 'MySQL',
  'postgresql' => 'PostgreSQL'
)
loader.setup

module WithAdvisoryLock
  LOCK_PREFIX_ENV = 'WITH_ADVISORY_LOCK_PREFIX'
end

ActiveSupport.on_load :active_record do
  include WithAdvisoryLock::Concern

  if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.include WithAdvisoryLock::PostgreSQL
  end

  if defined?(ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter)
    ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.include WithAdvisoryLock::MySQL
  end
end
