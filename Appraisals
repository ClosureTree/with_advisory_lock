# frozen_string_literal: true

appraise 'activerecord-4.2' do
  gem 'activerecord', '~> 4.2.0'
  platforms :ruby do
    gem 'pg', '~> 0.21'
    gem 'mysql2', '< 0.5'
    gem 'sqlite3', '~> 1.3.6'
  end
end

appraise 'activerecord-5.0' do
  gem 'activerecord', '~> 5.0.0'
  platforms :ruby do
    gem 'pg'
    gem 'mysql2'
    gem 'sqlite3'
  end
end

appraise 'activerecord-5.1' do
  gem 'activerecord', '~> 5.1.0'
  platforms :ruby do
    gem 'sqlite3'
    gem 'mysql2'
    gem 'pg'
  end
end

appraise 'activerecord-5.2' do
  gem 'activerecord', '~> 5.1.0'
  platforms :ruby do
    gem 'sqlite3', '~> 1.3.6'
    gem 'mysql2'
    gem 'pg'
  end
end

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
