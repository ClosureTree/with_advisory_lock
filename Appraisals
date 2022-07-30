# frozen_string_literal: true

appraise 'activerecord-6.0' do
  gem 'activerecord', '~> 6.0.0'
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
end

appraise 'activerecord-6.1' do
  gem 'activerecord', '~> 6.1.0'
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
end

appraise 'activerecord-7.0' do
  gem 'activerecord', '~> 7.0.0'
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
end

appraise 'activerecord-edge' do
  gem 'activerecord', github: 'rails/rails', branch: 'main'
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
end
