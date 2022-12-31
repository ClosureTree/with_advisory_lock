# frozen_string_literal: true

require 'English'
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/with_advisory_lock/version'

Gem::Specification.new do |spec|
  spec.name          = 'with_advisory_lock'
  spec.version       = WithAdvisoryLock::VERSION
  spec.authors       = ['Matthew McEachen', 'Abdelkader Boudih']
  spec.email         = %w[matthew+github@mceachen.org terminale@gmail.com]
  spec.homepage      = 'https://github.com/ClosureTree/with_advisory_lock'
  spec.summary       = 'Advisory locking for ActiveRecord'
  spec.description   = 'Advisory locking for ActiveRecord'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = %w[lib]
  spec.metadata      = { "rubyspecs_mfa_required" => "true" }
  spec.required_ruby_version = '>= 2.6.8'
  spec.metadata["yard.run"] = "yri"

  spec.add_runtime_dependency 'activerecord', '>= 6.0'

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'maxitest'
  spec.add_development_dependency 'minitest-great_expectations'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'yard'
end
