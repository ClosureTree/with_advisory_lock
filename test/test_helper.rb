# frozen_string_literal: true

ENV['RAILS_ENV'] = 'test'

require_relative 'dummy/config/environment'
ActiveRecord::Migrator.migrations_paths = [File.expand_path('../test/dummy/db/migrate', __dir__)]
require 'rails/test_help'

ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

def env_db
  @env_db ||= ApplicationRecord.connection_db_config.adapter.to_sym
end

require 'mocha/minitest'

class GemTestCase < ActiveSupport::TestCase
  setup do
    ENV['FLOCK_DIR'] = Dir.mktmpdir
  end
  teardown do
    FileUtils.remove_entry_secure ENV['FLOCK_DIR']
  end
end

puts "Testing with #{env_db} database, ActiveRecord #{ActiveRecord.gem_version} and #{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} as #{RUBY_VERSION}"
