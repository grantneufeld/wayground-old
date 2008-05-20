# Be sure to restart your server when you modify this file

# See: http://glu.ttono.us/articles/2006/05/22/configuring-rails-environments-the-cheat-sheet
# and: http://glu.ttono.us/articles/2006/05/22/guide-environments-in-rails-1-1

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
	# Settings in config/environments/* take precedence over those specified here.
	# Application configuration should go into files in config/initializers
	# -- all .rb files in that directory are automatically loaded.
	# See Rails::Configuration for more options.
	
	# Skip frameworks you're not going to use (only works if using vendor/rails).
	# To use Rails without a database, you must remove the Active Record framework
	# config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
	
	# Only load the plugins named here, in the order given. By default, all plugins 
	# in vendor/plugins are loaded in alphabetical order.
	# :all can be used as a placeholder for all plugins not explicitly named
	# config.plugins = [ :exception_notification, :ssl_requirement, :all ]
	
	# Add additional load paths for your own custom dirs
	# config.load_paths += %W( #{RAILS_ROOT}/extras )
	
	# Force all environments to use the same logger level
	# (by default production uses :info, the others :debug)
	# config.log_level = :debug
	
	# Your secret key for verifying cookie session data integrity.
	# If you change this key, all old sessions will become invalid!
	# Make sure the secret is at least 30 characters and all random, 
	# no regular words or you'll be exposed to dictionary attacks.
	config.action_controller.session = {
		:session_key => '_wayground_session',
		:secret      => 'ea6e4ea18d4d8d34a96d7b1a37412aaaf2445ab0287a0731e00faba1a723ad3b1a6f0e421bd14b17cee00e00a5484a55680dc4ca222f5dd46e2229a38945cd7e'
	}
	
	# Use the database for sessions instead of the cookie-based default,
	# which shouldn't be used to store highly confidential information
	# (create the session table with 'rake db:sessions:create')
	# Options: :active_record_store, :p_store, drb_store, :mem_cache_store, or :memory_store
	config.action_controller.session_store = :active_record_store
	#config.action_controller.session = { :session_key => "_openidauth_multiopenid_session", :secret => "mocramagic" }
	
	# Use SQL instead of Active Record's schema dumper when creating the test database.
	# This is necessary if your schema can't be completely dumped by the schema dumper,
	# like if you have constraints or database-specific column types
	config.active_record.schema_format = :sql
	
	# Activate observers that should always be running
	# config.active_record.observers = :cacher, :garbage_collector
	
	# Make Active Record use UTC-base instead of local time
	config.active_record.default_timezone = :utc
	# TODO: should I use this here, too?:
	#ENV['TZ'] = 'UTC'
	
	config.action_view.cache_template_loading = false
	
	# See Rails::Configuration for more options
	
	# To instruct the browser only to send the cookie over encrypted HTTPS
	# and never over normal HTTP:
	#ActionController::Base.session_options[:session_secure] = true
end


# Include your application configuration below

require 'tzinfo'
require 'will_paginate'
require 'action_mailer/ar_mailer'
ActionMailer::ARMailer::email_class = Notification


# Stuff from the caboo.se sample app, version 3:

#ExceptionNotifier.exception_recipients = %w( your_email@test.com )

# cool AR logging hack
#require 'ar_extensions'
