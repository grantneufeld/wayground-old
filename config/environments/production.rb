# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Enable threaded mode
# config.threadsafe!

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
#config.action_view.cache_template_loading            = true
config.cache_classes = true

# Use a different cache store in production
# config.cache_store = :memory_store
# config.cache_store = :file_store, '/path/to/cache'
# config.cache_store = :mem_cache_store
# config.cache_store = :mem_cache_store, :namespace=> 'storeapp'
# config.cache_store = :mem_cache_store, '123.456.789.0:1001', '123.456.789.0:1002'

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false
#config.action_mailer.delivery_method = :activerecord
config.action_mailer.delivery_method = :sendmail
#ActionMailer::Base.delivery_method = :smtp
#ActionMailer::Base.smtp_settings = {

# TODO: Change this to reflect your local smtp server
#config.action_mailer.smtp_settings = {
#    :address => "66.18.225.132",
#    :port => 25,
#    :domain => "www.wayground.ca" #,
#    #:user_name => "postmaster",
#    #:password => "MyPassword",
#    #:authentication => :login
#}

# TODO: ??? Not sure why I put this here.
ActionController::CgiRequest::DEFAULT_SESSION_OPTIONS[:session_key] = 'wayground_key'
