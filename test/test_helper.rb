# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require_relative 'dummy/config/environment'
ActiveRecord::Migrator.migrations_paths = [File.expand_path('../test/dummy/db/migrate', __dir__)]
require 'rails/test_help'

ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

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
  end

  teardown do
    FileUtils.remove_entry_secure(ENV['FLOCK_DIR'], true) if is_sqlite3_adapter?
  end
end

# puts "Testing with #{env_db} database, ActiveRecord #{ActiveRecord.gem_version} and #{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} as #{RUBY_VERSION}"
