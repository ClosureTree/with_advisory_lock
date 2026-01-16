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
    # Validate required environment variables
    %w[DATABASE_URL_PG DATABASE_URL_MYSQL].each do |var|
      abort "Missing required environment variable: #{var}" if ENV[var].nil? || ENV[var].empty?
    end

    # Trilogy is optional (not supported on TruffleRuby)
    if ENV['DATABASE_URL_TRILOGY'].nil? || ENV['DATABASE_URL_TRILOGY'].empty?
      puts 'DATABASE_URL_TRILOGY not set, skipping Trilogy tests'
    end
  end

  def self.trilogy_available?
    ENV['DATABASE_URL_TRILOGY'] && !ENV['DATABASE_URL_TRILOGY'].empty?
  end

  # Override in test classes to clean only the tables you need
  # This avoids unnecessary database operations
end

puts "Testing ActiveRecord #{ActiveRecord.gem_version} and ruby #{RUBY_VERSION}"
puts "Connection Pool size: #{ActiveRecord::Base.connection_pool.size}"
