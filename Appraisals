# frozen_string_literal: true

appraise 'activerecord-7.1' do
  gem 'activerecord', '~> 7.1.0'
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'trilogy'
    gem 'pg'
  end
  platforms :jruby do
    jdbc_version = {github: 'jruby/activerecord-jdbc-adapter', ref: 'master'}
    gem "activerecord-jdbcmysql-adapter", **jdbc_version
    gem "activerecord-jdbcpostgresql-adapter", **jdbc_version
    gem "activerecord-jdbcsqlite3-adapter", **jdbc_version
  end
end

appraise 'activerecord-7.0' do
  gem 'activerecord', '~> 7.0.0'
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'trilogy'
    gem "activerecord-trilogy-adapter"
    gem 'pg'
  end
  platforms :jruby do
    jdbc_version = '~> 70.0'
    gem "activerecord-jdbcmysql-adapter", jdbc_version
    gem "activerecord-jdbcpostgresql-adapter", jdbc_version
    gem "activerecord-jdbcsqlite3-adapter", jdbc_version
  end
end

appraise 'activerecord-6.1' do
  gem 'activerecord', '~> 6.1.0'

  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'trilogy'
    gem "activerecord-trilogy-adapter"
    gem 'pg'
  end
  platforms :jruby do
    jdbc_version = '~> 61.0'
    gem "activerecord-jdbcmysql-adapter", jdbc_version
    gem "activerecord-jdbcpostgresql-adapter", jdbc_version
    gem "activerecord-jdbcsqlite3-adapter", jdbc_version
  end
end

