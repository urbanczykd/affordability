require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Affordability
  class Application < Rails::Application
    config.load_defaults 7.2

    # API-only mode: no views, sessions, cookies, or asset pipeline
    config.api_only = true

    # Use Sidekiq as the Active Job queue adapter
    config.active_job.queue_adapter = :sidekiq

    # Autoload paths
    config.autoload_paths += %W[#{config.root}/app/services #{config.root}/app/jobs]

    # CORS is configured in config/initializers/cors.rb

    # Default to UTC
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
  end
end
