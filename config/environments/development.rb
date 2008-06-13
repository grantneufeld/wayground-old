# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

config.action_view.cache_template_loading = false

# Report errors if the mailer can't send?
config.action_mailer.raise_delivery_errors = true

#config.action_mailer.delivery_method = :sendmail
config.action_mailer.delivery_method = :activerecord
#ActionMailer::Base.delivery_method = :activerecord
#config.action_mailer.delivery_method = :smtp
#ActionMailer::Base.delivery_method = :smtp
#ActionMailer::Base.smtp_settings = {
config.action_mailer.smtp_settings = {
    :address => "mail.wayground.ca",
    :port => 25,
    :domain => "g.wayground.ca" #,
    #:user_name => "postmaster",
    #:password => "MyPassword",
    #:authentication => :login
}


# this should be set in the initializer, which might not actually get called until after this
module Wayground
	unless defined?(SITES)
		SITES = {
			4=>{:name=>'Arusha', :abbrev=>'arusha', :url=>'http://arusha.org'},
			8=>{:name=>'Calgary Dollars', :abbrev=>'caldol',
				:url=>'http://calgarydollars.ca'},
			16=>{:name=>'Action Films', :abbrev=>'actionfilms',
				:url=>'http://films.arusha.org'}
			}
	end
end
# override site urls to go to localhost while in development mode
Wayground::SITES.each_key do |key|
	Wayground::SITES[key][:url] = 'http://localhost:3000'
end
