# frozen_string_literal: true

require 'erb'
require 'active_record'
require 'with_advisory_lock'
require 'tmpdir'
require 'securerandom'

def env_db
  ENV.fetch('DB_ADAPTER', :sqlite).to_sym
end

db_config = File.expand_path('database.yml', File.dirname(__FILE__))
ActiveRecord::Base.configurations = YAML.safe_load(ERB.new(IO.read(db_config)).result)

ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

ActiveRecord::Base.establish_connection(env_db)
ActiveRecord::Migration.verbose = false

require 'test_models'
require 'minitest'
require 'minitest/autorun'
require 'minitest/great_expectations'
require 'mocha/minitest'

puts "Testing with #{env_db} database , ActiveRecord #{ActiveRecord.gem_version} and #{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} as #{RUBY_VERSION}"
module MiniTest
  class Spec
    before do
      ENV['FLOCK_DIR'] = Dir.mktmpdir
      Tag.delete_all
      TagAudit.delete_all
      Label.delete_all
    end
    after do
      FileUtils.remove_entry_secure ENV['FLOCK_DIR']
    end
  end
end
