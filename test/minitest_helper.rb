require 'erb'
require 'active_record'
require 'with_advisory_lock'
require 'tmpdir'

db_config = File.expand_path("database.yml", File.dirname(__FILE__))
ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(db_config)).result)

def env_db
  (ENV["DB"] || "mysql").to_sym
end

ActiveRecord::Base.establish_connection(env_db)
ActiveRecord::Migration.verbose = false

require 'test_models'
require 'minitest/autorun'
require 'minitest/great_expectations'
require 'mocha/setup'

Thread.abort_on_exception = true

def test_lock_exists?
  [:mysql, :postgres].include? env_db
end

class MiniTest::Spec
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

