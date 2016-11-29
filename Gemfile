source 'https://rubygems.org'

gemspec

platforms :ruby do
  gem 'mysql2', '~> 0.3.10' # Rails 3.2 requires 0.3.x
  gem 'pg', '< 0.19' # 0.19 requires Ruby 2.0+
  gem 'sqlite3'
end

platforms :jruby do
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'
end
