# frozen_string_literal: true

require File.expand_path("boot", __dir__)

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module TestSystemApp
  class Application < Rails::Application
    config.load_defaults [ Rails::VERSION::MAJOR, Rails::VERSION::MINOR ].join(".")
    config.eager_load = true
    config.serve_static_files = false
    config.public_file_server.enabled = false
    config.public_file_server.headers = { "Cache-Control" => "public, max-age=3600" }
    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false
    config.action_dispatch.show_exceptions = false
    config.action_controller.allow_forgery_protection = false
    config.active_support.test_order = :random
    config.active_support.deprecation = :stderr
    config.active_record.timestamped_migrations = false
  end
end
