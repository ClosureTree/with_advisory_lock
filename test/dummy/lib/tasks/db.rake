# frozen_string_literal: true

namespace :db do
  namespace :test do
    desc 'Load schema for all databases'
    task prepare: :environment do
      # Setup PostgreSQL database
      ActiveRecord::Base.establish_connection(:primary)
      load Rails.root.join('db', 'schema.rb')
      puts 'PostgreSQL database schema loaded'

      # Setup MySQL database
      ActiveRecord::Base.establish_connection(:secondary)
      load Rails.root.join('db', 'secondary_schema.rb')
      puts 'MySQL database schema loaded'

      # Setup Trilogy database (MariaDB) - optional, not supported on TruffleRuby
      if ENV['DATABASE_URL_TRILOGY'] && !ENV['DATABASE_URL_TRILOGY'].empty?
        ActiveRecord::Base.establish_connection(:trilogy)
        load Rails.root.join('db', 'trilogy_schema.rb')
        puts 'Trilogy database schema loaded'
      else
        puts 'Skipping Trilogy database (DATABASE_URL_TRILOGY not set)'
      end

      puts 'All test databases prepared successfully'
    rescue StandardError => e
      puts "Error preparing test databases: #{e.message}"
      raise e
    end
  end
end
