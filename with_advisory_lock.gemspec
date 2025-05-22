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
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = %w[lib]
  spec.metadata      = { 'rubygems_mfa_required' => 'true' }
  spec.required_ruby_version = '>= 3.3.0'
  spec.metadata['yard.run'] = 'yri'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ClosureTree/with_advisory_lock'
  spec.metadata['changelog_uri'] = 'https://github.com/ClosureTree/with_advisory_lock/blob/master/CHANGELOG.md'

  spec.post_install_message = <<~MESSAGE
    SQLite support has been removed and MySQL 5.7 is no longer supported.
    If you rely on either, lock this gem to an older version or migrate to
    MySQL 8 or PostgreSQL.
  MESSAGE

  spec.add_runtime_dependency 'activerecord', '>= 7.1'
  spec.add_runtime_dependency 'zeitwerk', '>= 2.7'

  spec.add_development_dependency 'appraisal'
  spec.add_development_dependency 'maxitest'
  spec.add_development_dependency 'minitest-reporters'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'yard'
end
