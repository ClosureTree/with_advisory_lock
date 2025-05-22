# frozen_string_literal: true

require 'securerandom'

ENV['RAILS_ENV'] = 'test'
ENV['WITH_ADVISORY_LOCK_PREFIX'] ||= SecureRandom.hex

require 'dotenv'
Dotenv.load

require_relative 'dummy/config/environment'
require 'rails/test_help'

require 'with_advisory_lock'
require 'maxitest/autorun'
require 'mocha/minitest'

class GemTestCase < ActiveSupport::TestCase
  parallelize(workers: 1)

  def self.startup
    # Validate environment variables when tests actually start running
    %w[DATABASE_URL_PG DATABASE_URL_MYSQL].each do |var|
      abort "Missing required environment variable: #{var}" if ENV[var].nil? || ENV[var].empty?
    end
  end

  # Override in test classes to clean only the tables you need
  # This avoids unnecessary database operations
end

puts "Testing ActiveRecord #{ActiveRecord.gem_version} and ruby #{RUBY_VERSION}"
puts "Connection Pool size: #{ActiveRecord::Base.connection_pool.size}"
