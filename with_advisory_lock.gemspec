# frozen_string_literal: true

require 'English'
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
  spec.require_paths = %w[lib]
  spec.metadata      = { 'rubygems_mfa_required' => 'true' }
  spec.required_ruby_version = '>= 3.3.0'
  spec.metadata['yard.run'] = 'yri'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ClosureTree/with_advisory_lock'
  spec.metadata['changelog_uri'] = 'https://github.com/ClosureTree/with_advisory_lock/blob/master/CHANGELOG.md'

  spec.add_dependency 'activerecord', '>= 7.2'
  spec.add_dependency 'zeitwerk', '>= 2.7'

  spec.add_development_dependency 'maxitest', '6.2.0'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'yard'
end
