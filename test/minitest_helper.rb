require 'erb'
require 'active_record'
require 'with_advisory_lock'
require 'database_cleaner'
require 'tmpdir'

db_config = File.expand_path("database.yml", File.dirname(__FILE__))
ActiveRecord::Base.configurations = YAML::load(ERB.new(IO.read(db_config)).result)
ActiveRecord::Base.establish_connection(ENV["DB"] || "sqlite")
ActiveRecord::Migration.verbose = false

require 'test_models'
require 'minitest/autorun'

Thread.abort_on_exception = true

DatabaseCleaner.strategy = :deletion
class MiniTest::Spec
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
  end
  before :all do
    ENV['FLOCK_DIR'] = Dir.mktmpdir
  end
  after :all do
    FileUtils.remove_entry_secure ENV['FLOCK_DIR']
  end
end

