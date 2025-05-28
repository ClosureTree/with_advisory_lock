# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'rake'

# Gems that will be removed from default gems in Ruby 3.5.0
gem 'benchmark'
gem 'logger'
gem 'ostruct'

activerecord_version = ENV.fetch('ACTIVERECORD_VERSION', '7.1')

gem 'activerecord', "~> #{activerecord_version}.0"

gem 'dotenv'
gem 'railties'

platforms :ruby do
  gem 'mysql2'
  gem 'pg'
  gem 'trilogy'
end

platforms :jruby do
  # JRuby JDBC adapters only support Rails 7.1 currently
  if activerecord_version == '7.1'
    gem 'activerecord-jdbcmysql-adapter', '~> 71.0'
    gem 'activerecord-jdbcpostgresql-adapter', '~> 71.0'
  end
end
