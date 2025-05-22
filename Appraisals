# frozen_string_literal: true

appraise 'activerecord-7.1' do
  gem 'activerecord', '~> 7.1.0'
  platforms :ruby do
    gem 'mysql2'
    gem 'trilogy'
    gem 'pg'
  end
 platforms :jruby do
    gem "activerecord-jdbcmysql-adapter"
    gem "activerecord-jdbcpostgresql-adapter"
  end
end


appraise 'activerecord-7.2' do
  gem 'activerecord', '~> 7.2.0'
  platforms :ruby do
    gem 'mysql2'
    gem 'trilogy'
    gem 'pg'
  end
end

appraise 'activerecord-8.0' do
  gem 'activerecord', '~> 8.0.0'
  platforms :ruby do
    gem 'mysql2'
    gem 'trilogy'
    gem 'pg'
  end
end
