require "sidekiq"
require "sidekiq/web"
require "rack/session"

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

session_secret = ENV.fetch("SESSION_SECRET") { File.exist?(".session.key") ? File.read(".session.key") : SecureRandom.hex(32) }

Sidekiq::Web.use Rack::Session::Cookie,
  secret: session_secret,
  same_site: true,
  max_age: 86400

run Sidekiq::Web


# Note: Sidekiq::Web has no authentication by default. For anything beyond local dev, add HTTP basic auth to sidekiq_web.ru:                                            
#Sidekiq::Web.use Rack::Auth::Basic do |u, p|
#  u == "admin" && p == ENV.fetch("SIDEKIQ_WEB_PASSWORD", "darek")
#end   