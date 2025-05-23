# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'rake'

activerecord_version = ENV.fetch('ACTIVERECORD_VERSION', '7.1')

gem 'activerecord', "~> #{activerecord_version}.0"

gem 'railties'

platforms :ruby do
  gem 'mysql2'
  gem 'pg'
  gem 'trilogy'
end

platforms :jruby do
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbcpostgresql-adapter'
end
