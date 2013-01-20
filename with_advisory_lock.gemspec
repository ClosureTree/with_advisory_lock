# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'with_advisory_lock/version'

Gem::Specification.new do |gem|
  gem.name          = "with_advisory_lock"
  gem.version       = WithAdvisoryLock::VERSION
  gem.authors       = ["Matthew McEachen"]
  gem.email         = ["matthew+github@mceachen.org"]
  gem.description   = %q{Advisory locking for ActiveRecord}
  gem.summary       = gem.description
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^test/})
  gem.require_paths = %w(lib)

  gem.add_runtime_dependency 'activerecord', '>= 3.0.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'mysql2'
  gem.add_development_dependency 'pg'
  gem.add_development_dependency 'sqlite3'
  gem.add_development_dependency 'database_cleaner'
end
