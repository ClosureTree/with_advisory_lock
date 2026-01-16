# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'rake'

# Gems that will be removed from default gems in Ruby 3.5.0
gem 'benchmark'
gem 'logger'
gem 'ostruct'

activerecord_version = ENV.fetch('ACTIVERECORD_VERSION', '8.1')

if activerecord_version == 'edge'
  gem 'activerecord', github: 'rails/rails', branch: 'main'
  gem 'railties', github: 'rails/rails', branch: 'main'
else
  gem 'activerecord', "~> #{activerecord_version}.0"
  gem 'railties'
end

gem 'dotenv'

platforms :ruby do
  gem 'mysql2'
  gem 'pg'
  gem 'sqlite3'
  gem 'trilogy'
end

platforms :jruby do
  # JRuby JDBC adapters support Rails 7.2+
  if activerecord_version >= '7.2'
    gem 'activerecord-jdbcmysql-adapter', '~> 72.0'
    gem 'activerecord-jdbcpostgresql-adapter', '~> 72.0'
  end
end
