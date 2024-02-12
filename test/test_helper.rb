# frozen_string_literal: true

require 'erb'
require 'active_record'
require 'with_advisory_lock'
require 'tmpdir'
require 'securerandom'
begin
  require 'activerecord-trilogy-adapter'
  ActiveSupport.on_load(:active_record) do
    require "trilogy_adapter/connection"
    ActiveRecord::Base.public_send :extend, TrilogyAdapter::Connection
  end
rescue LoadError
  # do nothing
end

ActiveRecord::Base.configurations = {
  default_env: {
    url: ENV.fetch('DATABASE_URL', "sqlite3://#{Dir.tmpdir}/with_advisory_lock_test#{RUBY_VERSION}-#{ActiveRecord.gem_version}.sqlite3"),
    properties: { allowPublicKeyRetrieval: true } # for JRuby madness
  }
}

ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

ActiveRecord::Base.establish_connection

def env_db
  @env_db ||= ActiveRecord::Base.connection_db_config.adapter.to_sym
end

ActiveRecord::Migration.verbose = false

require 'test_models'
require 'minitest'
require 'maxitest/autorun'
require 'mocha/minitest'

class GemTestCase < ActiveSupport::TestCase

  parallelize(workers: 1)
  def adapter_support
    @adapter_support ||= WithAdvisoryLock::DatabaseAdapterSupport.new(ActiveRecord::Base.connection)
  end
  def is_sqlite3_adapter?; adapter_support.sqlite?; end
  def is_mysql_adapter?; adapter_support.mysql?; end
  def is_postgresql_adapter?; adapter_support.postgresql?; end

  setup do
    ENV['FLOCK_DIR'] = Dir.mktmpdir if is_sqlite3_adapter?
    ApplicationRecord.connection.truncate_tables(
      Tag.table_name,
      TagAudit.table_name,
      Label.table_name
    )
  end

  teardown do
    FileUtils.remove_entry_secure(ENV['FLOCK_DIR'], true) if is_sqlite3_adapter?
  end
end

puts "Testing with #{env_db} database, ActiveRecord #{ActiveRecord.gem_version} and #{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} as #{RUBY_VERSION}"
puts "Connection Pool size: #{ActiveRecord::Base.connection_pool.size}"