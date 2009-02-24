# Be sure to restart your server when you modify this file

# See: http://glu.ttono.us/articles/2006/05/22/configuring-rails-environments-the-cheat-sheet
# and: http://glu.ttono.us/articles/2006/05/22/guide-environments-in-rails-1-1

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.2.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
	# Settings in config/environments/* take precedence over those specified here.
	# Application configuration should go into files in config/initializers
	# -- all .rb files in that directory are automatically loaded.
	# See Rails::Configuration for more options.
	
	# Skip frameworks you're not going to use. To use Rails without a database
	# you must remove the Active Record framework.
	# config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
	
	# Specify gems that this application depends on. 
	# They can then be installed with "rake gems:install" on new installations.
	# You have to specify the :lib option for libraries, where the Gem name (sqlite3-ruby) differs from the file itself (sqlite3)
	# config.gem "bj"
	# config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
	# config.gem "sqlite3-ruby", :lib => "sqlite3"
	# config.gem "aws-s3", :lib => "aws/s3"
	config.gem 'ruby-prof'
##	config.gem 'ruby-openid'
	config.gem 'ar_mailer', :lib=>'action_mailer/ar_mailer'
##	config.gem 'ar_mailer_generator'
#	config.gem 'tzinfo'
	config.gem 'chronic'
	config.gem 'will_paginate'
	config.gem 'image_science'
	config.gem 'RedCloth', :version=>'>= 3.301',
		:source=>'http://code.whytheluckystiff.net/'
	
	# Only load the plugins named here, in the order given. By default, all plugins 
	# in vendor/plugins are loaded in alphabetical order.
	# :all can be used as a placeholder for all plugins not explicitly named
	# config.plugins = [ :exception_notification, :ssl_requirement, :all ]
	
	# Add additional load paths for your own custom dirs
	# config.load_paths += %W( #{RAILS_ROOT}/extras )
	
	# Force all environments to use the same logger level
	# (by default production uses :info, the others :debug)
	# config.log_level = :debug
	
	# Make Time.zone default to the specified zone, and make Active Record store time values
	# in the database in UTC, and return them converted to the specified local zone.
	# Run "rake -D time" for a list of tasks for finding time zone names. Comment line to use default local time.
	#config.time_zone = 'UTC'
	# Rails 2.1 approach:
	config.time_zone = 'Mountain Time (US & Canada)'
	
	# The internationalization framework can be changed to have another default locale (standard is :en) or more load paths.
	# All files from config/locales/*.rb,yml are added automatically.
	# config.i18n.load_path << Dir[File.join(RAILS_ROOT, 'my', 'locales', '*.{rb,yml}')]
	# config.i18n.default_locale = :de
	
	# Your secret key for verifying cookie session data integrity.
	# If you change this key, all old sessions will become invalid!
	# Make sure the secret is at least 30 characters and all random, 
	# no regular words or you'll be exposed to dictionary attacks.
	# YAML loading based on:
	# http://almosteffortless.com/2007/12/27/configuring-cookie-based-sessions-in-rails-20/
	require 'yaml'
	db = YAML.load_file('config/database.yml')
	config.action_controller.session = {
		:session_key => db[RAILS_ENV]['session_key'],
		:secret      => db[RAILS_ENV]['secret']
	}
	
	# Use the database for sessions instead of the cookie-based default,
	# which shouldn't be used to store highly confidential information
	# (create the session table with "rake db:sessions:create")
	# Options: :active_record_store, :p_store, drb_store, :mem_cache_store, or :memory_store
	config.action_controller.session_store = :active_record_store
	#config.action_controller.session = { :session_key => "_openidauth_multiopenid_session", :secret => "mocramagic" }
	
	# Use SQL instead of Active Record's schema dumper when creating the test database.
	# This is necessary if your schema can't be completely dumped by the schema dumper,
	# like if you have constraints or database-specific column types
	config.active_record.schema_format = :sql
	
	# Activate observers that should always be running
	# Please note that observers generated using script/generate observer need to have an _observer suffix
	# config.active_record.observers = :cacher, :garbage_collector, :forum_observer
	
	# Make Active Record use UTC-base instead of local time
#	config.active_record.default_timezone = :utc
	
#	config.action_view.cache_template_loading = false
	
	# See Rails::Configuration for more options
	
	# To instruct the browser only to send the cookie over encrypted HTTPS
	# and never over normal HTTP:
	#ActionController::Base.session_options[:session_secure] = true
	
	# Make ActiveRecord only save the attributes that have changed since the record was loaded.
	config.active_record.partial_updates = true
end


# Include your application configuration below

require 'will_paginate'
require 'action_mailer/ar_mailer'
ActionMailer::ARMailer::email_class = Notification


# Stuff from the caboo.se sample app, version 3:

#ExceptionNotifier.exception_recipients = %w( your_email@test.com )

# cool AR logging hack
#require 'ar_extensions'
