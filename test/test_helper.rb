# frozen_string_literal: true

require 'erb'
require 'active_record'
require 'with_advisory_lock'
require 'tmpdir'
require 'securerandom'

ActiveRecord::Base.configurations = {
  default_env: {
    url: ENV.fetch('DATABASE_URL', "sqlite3://#{Dir.tmpdir}/#{SecureRandom.hex}.sqlite3"),
    properties: { allowPublicKeyRetrieval: true } # for JRuby madness
  }
}

ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

ActiveRecord::Base.establish_connection

def env_db
  @env_db ||= if ActiveRecord::Base.respond_to?(:connection_db_config)
                ActiveRecord::Base.connection_db_config.adapter
              else
                ActiveRecord::Base.connection_config[:adapter]
              end.to_sym
end

ActiveRecord::Migration.verbose = false

require 'test_models'
require 'minitest'
require 'maxitest/autorun'
require 'minitest/great_expectations'
require 'mocha/minitest'

puts "Testing with #{env_db} database, ActiveRecord #{ActiveRecord.gem_version} and #{RUBY_ENGINE} #{RUBY_ENGINE_VERSION} as #{RUBY_VERSION}"
module MiniTest
  class Spec
    before do
      ActiveRecord::Base.establish_connection
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
