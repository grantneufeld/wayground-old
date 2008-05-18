# Settings specified here will take precedence over those in config/environment.rb

# The test environment is used exclusively to run your application's
# test suite.  You never need to work with it otherwise.  Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs.  Don't rely on the data there!
config.cache_classes = true

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching = false
config.action_view.cache_template_loading = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection = false

# Tell ActionMailer not to deliver emails to the real world.
# The :test delivery method accumulates sent emails in the
# ActionMailer::Base.deliveries array.
config.action_mailer.raise_delivery_errors = true
config.action_mailer.delivery_method = :activerecord
#config.action_mailer.delivery_method = :test
config.action_mailer.perform_deliveries = false
config.action_mailer.smtp_settings = {
    :address=>"127.0.0.1",
    :port=>25,
    :domain=>"g.wayground.ca" #,
    #:user_name => "postmaster",
    #:password => "MyPassword",
    #:authentication => :login
}

begin
	require 'ruby-debug'
rescue
end
