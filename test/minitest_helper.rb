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
require 'minitest/great_expectations'
require 'mocha/setup'

Thread.abort_on_exception = true

DatabaseCleaner.strategy = :deletion
class MiniTest::Spec
  before do
    ENV['FLOCK_DIR'] = Dir.mktmpdir
    DatabaseCleaner.start
  end
  after do
    FileUtils.remove_entry_secure ENV['FLOCK_DIR']
    DatabaseCleaner.clean
  end
end

