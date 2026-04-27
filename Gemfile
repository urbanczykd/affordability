source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem "rails", "~> 7.2.0"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "sidekiq", "~> 7.2"
gem "rack-cors", "~> 2.0"
gem "dotenv-rails", "~> 3.1"

group :development, :test do
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 6.1"
  gem "database_cleaner-active_record", "~> 2.1"
end

group :development do
  gem "listen", "~> 3.8"
end
