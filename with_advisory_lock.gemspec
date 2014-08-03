# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'with_advisory_lock/version'

Gem::Specification.new do |gem|
  gem.name          = "with_advisory_lock"
  gem.version       = WithAdvisoryLock::VERSION
  gem.authors       = ['Matthew McEachen']
  gem.email         = %w(matthew+github@mceachen.org)
  gem.homepage      = 'https://github.com/mceachen/with_advisory_lock'
  gem.summary       = %q{Advisory locking for ActiveRecord}
  gem.description   = %q{Advisory locking for ActiveRecord}
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^test/})
  gem.require_paths = %w(lib)

  gem.add_runtime_dependency 'activerecord', '>= 3.2'
  gem.add_runtime_dependency 'thread_safe'

  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'minitest-great_expectations'
  gem.add_development_dependency 'minitest-reporters'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'appraisal'
end
