require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.enable_reloading = false
  config.eager_load = false
  config.consider_all_requests_local = true

  # Logging
  config.log_level = :warn

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = :none

  # Raise errors on unpermitted parameters.
  config.action_controller.raise_on_unpermitted_parameters = true

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation = :raise

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true

  # Use inline job adapter so jobs run synchronously in tests
  config.active_job.queue_adapter = :test
end
