# frozen_string_literal: true

require 'English'
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/with_advisory_lock/version'

Gem::Specification.new do |gem|
  gem.name          = 'with_advisory_lock'
  gem.version       = WithAdvisoryLock::VERSION
  gem.authors       = ['Matthew McEachen', 'Abdelkader Boudih']
  gem.email         = %w[matthew+github@mceachen.org terminale@gmail.com]
  gem.homepage      = 'https://github.com/ClosureTree/with_advisory_lock'
  gem.summary       = 'Advisory locking for ActiveRecord'
  gem.description   = 'Advisory locking for ActiveRecord'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.test_files    = gem.files.grep(%r{^test/})
  gem.require_paths = %w[lib]
  gem.metadata      = { "rubygems_mfa_required" => "true" }
  gem.required_ruby_version = '>= 2.6.8'

  gem.add_runtime_dependency 'activerecord', '>= 6.0'

  gem.add_development_dependency 'appraisal'
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'minitest-great_expectations'
  gem.add_development_dependency 'minitest-reporters'
  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'yard'
end
