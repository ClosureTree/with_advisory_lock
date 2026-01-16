# frozen_string_literal: true

require File.expand_path('boot', __dir__)

require 'rails'
require 'active_model/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

module TestSystemApp
  class Application < Rails::Application
    config.load_defaults [Rails::VERSION::MAJOR, Rails::VERSION::MINOR].join('.')
    config.eager_load = true

    # Ignore trilogy models when DATABASE_URL_TRILOGY is not set (e.g., TruffleRuby)
    unless ENV['DATABASE_URL_TRILOGY'] && !ENV['DATABASE_URL_TRILOGY'].empty?
      config.autoload_lib(ignore: %w[])
      initializer 'ignore_trilogy_models', before: :set_autoload_paths do |app|
        trilogy_models = %w[trilogy_record trilogy_tag trilogy_tag_audit trilogy_label]
        trilogy_models.each do |model|
          Rails.autoloaders.main.ignore(Rails.root.join('app', 'models', "#{model}.rb"))
        end
      end
    end
    config.serve_static_files = false
    config.public_file_server.enabled = false
    config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }
    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false
    config.action_dispatch.show_exceptions = false
    config.action_controller.allow_forgery_protection = false
    config.active_support.test_order = :random
    config.active_support.deprecation = :stderr
    config.active_record.timestamped_migrations = false

    # Disable automatic database setup since we handle it manually
    config.active_record.maintain_test_schema = false if config.respond_to?(:active_record)
  end
end
