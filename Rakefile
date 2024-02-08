require "bundler/gem_tasks"

require 'yard'
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', 'README.md']
end

APP_RAKEFILE = File.expand_path("test/dummy/Rakefile", __dir__)
load APP_RAKEFILE
require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs.push 'lib'
  t.libs.push 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

task :default => :test
