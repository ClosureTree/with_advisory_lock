# frozen_string_literal: true

require 'erb'
require 'active_record'
require 'active_record/database_configurations'
require 'yaml'
require 'with_advisory_lock'
require 'tmpdir'
require 'securerandom'

db_config_path = File.expand_path('dummy/config/database.yml', __dir__)
db_config      = YAML.load(ERB.new(File.read(db_config_path)).result, aliases: true)
ActiveRecord::Base.configurations = ActiveRecord::DatabaseConfigurations.new(db_config)

ENV['RAILS_ENV'] ||= 'test'

ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

ActiveRecord::Base.establish_connection(:primary)

load File.expand_path('dummy/db/schema.rb', __dir__)

require_relative 'dummy/app/models/mysql_record'
if MysqlRecord.connected?
  ActiveRecord::Base.establish_connection(:secondary)
  load File.expand_path('dummy/db/schema.rb', __dir__)
  ActiveRecord::Base.establish_connection(:primary)
end

def env_db
  @env_db ||= ActiveRecord::Base.connection_db_config.adapter.to_sym
end

ActiveRecord::Migration.verbose = false

require_relative 'dummy/app/models/application_record'
require_relative 'dummy/app/models/tag'
require_relative 'dummy/app/models/tag_audit'
require_relative 'dummy/app/models/label'
require_relative 'dummy/app/models/mysql_tag'
require_relative 'dummy/app/models/mysql_tag_audit'
require_relative 'dummy/app/models/mysql_label'
require 'minitest'
require 'maxitest/autorun'
require 'mocha/minitest'

class GemTestCase < ActiveSupport::TestCase

  parallelize(workers: 1)
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

puts "Testing with #{env_db} database, ActiveRecord #{ActiveRecord.gem_version} and #{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} as #{RUBY_VERSION}"
puts "Connection Pool size: #{ActiveRecord::Base.connection_pool.size}"
