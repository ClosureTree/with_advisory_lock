# frozen_string_literal: true

require 'securerandom'

ENV['RAILS_ENV'] = 'test'
ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

require_relative 'dummy/config/environment'
require 'rails/test_help'

require 'with_advisory_lock'
require 'maxitest/autorun'
require 'mocha/minitest'

class GemTestCase < ActiveSupport::TestCase

  parallelize(workers: 1)

  def self.startup
    # Validate environment variables when tests actually start running
    %w[DATABASE_URL_PG DATABASE_URL_MYSQL].each do |var|
      if ENV[var].nil? || ENV[var].empty?
        abort "Missing required environment variable: #{var}"
      end
    end
  end
  # Automatically run migrations if needed
  ActiveRecord::Tasks::DatabaseTasks.maintain_test_schema!
  if MysqlRecord.connected?
    # Switch to MySQL connection temporarily
    old_connection = ActiveRecord::Base.connection
    ActiveRecord::Base.establish_connection(MysqlRecord.connection_config)
    ActiveRecord::Tasks::DatabaseTasks.maintain_test_schema!
    ActiveRecord::Base.establish_connection(old_connection.instance_variable_get(:@config))
  end

  def adapter_support
    @adapter_support ||= WithAdvisoryLock::DatabaseAdapterSupport.new(ActiveRecord::Base.connection)
  end
  def is_mysql_adapter?; adapter_support.mysql?; end
  def is_postgresql_adapter?; adapter_support.postgresql?; end

  setup do
    ApplicationRecord.connection.truncate_tables(
      Tag.table_name,
      TagAudit.table_name,
      Label.table_name
    )
    if MysqlRecord.connected?
      MysqlRecord.connection.truncate_tables(
        MysqlTag.table_name,
        MysqlTagAudit.table_name,
        MysqlLabel.table_name
      )
    end
  end

end

puts "Testing ActiveRecord #{ActiveRecord.gem_version} and #{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} as #{RUBY_VERSION}"
puts "Connection Pool size: #{ActiveRecord::Base.connection_pool.size}"
