# Settings specified here will take precedence over those in config/environment.rb

config.gem 'ruby-debug'
config.gem 'ZenTest'
config.gem 'assert2'
config.gem 'mocha'

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
#config.action_view.cache_template_loading = false
config.cache_classes = false

# Disable request forgery protection in test environment
config.action_controller.allow_forgery_protection = false

# Tell Action Mailer not to deliver emails to the real world.
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

require 'mocha'
Mocha::Configuration.prevent(:stubbing_non_existent_method)
Mocha::Configuration.prevent(:stubbing_method_unnecessarily)
Mocha::Configuration.prevent(:stubbing_non_public_method)

# for testing assignment to protected attributes.
# based on http://almosteffortless.com/2008/11/27/raising-protected-attribute-assignment-errors/
module Wayground
	# Assignment attempted to protected attribute(s).
	class AssignToProtectedAttribute < Exception; end
end
ActiveRecord::Base.class_eval do
	def log_protected_attribute_removal(*attributes)
		raise Wayground::AssignToProtectedAttribute.new("Can't mass-assign these protected attributes: #{attributes.join(', ')}")
	end
end
