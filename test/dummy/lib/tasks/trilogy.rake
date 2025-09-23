# frozen_string_literal: true

namespace :db do
  namespace :trilogy do
    desc 'Create and load the Trilogy database schema'
    task prepare: :environment do
      ActiveRecord::Base.establish_connection(:trilogy)

      # Load the schema
      load Rails.root.join('db', 'trilogy_schema.rb')

      puts 'Trilogy database schema loaded successfully'
    rescue StandardError => e
      puts "Error loading Trilogy schema: #{e.message}"
      raise e
    end
  end

  namespace :test do
    task prepare: :environment do
      # Setup PostgreSQL database
      ActiveRecord::Base.establish_connection(:primary)
      load Rails.root.join('db', 'schema.rb')

      # Setup MySQL database
      ActiveRecord::Base.establish_connection(:secondary)
      load Rails.root.join('db', 'secondary_schema.rb')

      # Setup Trilogy database
      ActiveRecord::Base.establish_connection(:trilogy)
      load Rails.root.join('db', 'trilogy_schema.rb')

      puts 'All test databases prepared successfully'
    end
  end
end