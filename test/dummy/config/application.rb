# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_record/railtie'
Bundler.require(*Rails.groups)
require 'with_advisory_lock'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
  end
end
