# frozen_string_literal: true

appraise 'activerecord-7.1' do
  gem 'activerecord', '~> 7.1.0'
  gem 'trilogy'
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
end

appraise 'activerecord-7.0' do
  gem 'activerecord', '~> 7.0.0'
  gem 'trilogy'
  gem "activerecord-trilogy-adapter"
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
  platforms :jruby do
    gem "activerecord-jdbcmysql-adapter"
    gem "activerecord-jdbcpostgresql-adapter"
    gem "activerecord-jdbcsqlite3-adapter"
  end
end

appraise 'activerecord-6.1' do
  gem 'activerecord', '~> 6.1.0'
  gem 'trilogy'
  gem "activerecord-trilogy-adapter"
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
  platforms :jruby do
    gem "activerecord-jdbcmysql-adapter"
    gem "activerecord-jdbcpostgresql-adapter"
    gem "activerecord-jdbcsqlite3-adapter"
  end
end

