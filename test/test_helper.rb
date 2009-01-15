ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
	# Transactional fixtures accelerate your tests by wrapping each test method
	# in a transaction that's rolled back on completion.  This ensures that the
	# test database remains unchanged so your fixtures don't have to be reloaded
	# between every test method.  Fewer database queries means faster tests.
	#
	# Read Mike Clark's excellent walkthrough at
	#   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
	#
	# Every Active Record database supports transactions except MyISAM tables
	# in MySQL.  Turn off transactional fixtures in this case; however, if you
	# don't care one way or the other, switching from MyISAM to InnoDB tables
	# is recommended.
	#
	# The only drawback to using transactional fixtures is when you actually 
	# need to test transactions.  Since your test is bracketed by a transaction,
	# any transactions started in your code will be automatically rolled back.
	self.use_transactional_fixtures = true
	
	# Instantiated fixtures are slow, but give you @david where otherwise you
	# would need people(:david).  If you don't want to migrate your existing
	# test cases which use the @david style and don't mind the speed hit (each
	# instantiated fixtures translates to a database query per test method),
	# then set this back to true.
	self.use_instantiated_fixtures  = false
	
	# Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
	#
	# Note: You'll currently still have to declare fixtures explicitly in integration tests
	# -- they do not yet inherit this setting
	#fixtures :all
	
	# Add more helper methods to be used by all tests here...
	
	# http://blog.caboo.se/articles/2006/11/04/automatically-test-your-associations
	# This is a basic “sanity check” for model associations.
	# In each unit test, add this (substituting the class for “<class>”):
	#	def test_associations
	#		assert check_associations(<class>)
	#	end
	def check_associations(m = nil, ignore = [])
		m ||= self.class.to_s.sub(/Test$/, '').constantize
		@m = m.new
		ig = [ignore].flatten
		m.reflect_on_all_associations.each do |assoc|
			next if ig.any?{|i| i == assoc.name}
			assert_nothing_raised("#{assoc.name} caused an error") do
				@m.send(assoc.name, true)
			end
		end
		true
	end
	
	# Test that the routes for a resource defined in routes.rb are working as expected.
	# E.g., in routes.rb:
	#   map.resources :things
	# controller='things'
	# Some routes may be overridden elsewhere in routes.rb. E.g.:
	#   map.myspecial '/special', :controller=>'things', :action=>'new'
	#   map.resources :things
	# skip=['new']
	# If using nested resources, set the nesting array (use singular strings).
	#   map.resources :nests do |nest|
	#     nest.resources :things
	#   end
	# nesting=['nest']
	# You can add actions in addition to the standard REST actions:
	#  map.resources :things, :collection=>{:otheraction=>:get}
	
	# Test for routes generated by map.resource (singular).
	def assert_routing_for_resource(controller, skip=[], nesting=[], collection={}, member={}, resource=nil)
		routes = [
			["new",'/new',{},:get], ["create",'',{},:post],
			["show",'',{},:get], ["edit",'/edit',{},:get],
			["update",'',{},:put], ["destroy",'',{},:delete]
			]
		collection.each_pair do |k,v|
			routes << [k.to_s, "/#{k}", {}, v]
		end
		member.each_pair do |k,v|
			routes << [k.to_s, "/1/#{k}", {:id=>'1'}, v]
		end
		check_resource_routing(controller, routes, skip, nesting, resource)
	end
	# Test for routes generated by map.resources (plural).
	def assert_routing_for_resources(controller, skip=[], nesting=[], collection={}, member={}, resource=nil)
		routes = [
			["index",'',{},:get], ["new",'/new',{},:get], ["create",'',{},:post],
			["show",'/1',{:id=>'1'},:get], ["edit",'/1/edit',{:id=>'1'},:get],
			["update",'/1',{:id=>'1'},:put], ["destroy",'/1',{:id=>'1'},:delete]
			]
		collection.each_pair do |k,v|
			routes << [k.to_s, "/#{k}", {}, v]
		end
		member.each_pair do |k,v|
			routes << [k.to_s, "/1/#{k}", {:id=>'1'}, v]
		end
		check_resource_routing(controller, routes, skip, nesting, resource)
	end
	
	# Check that the expected paths will be generated by a resource, and that
	# the expected params will be generated by paths defined by a resource.
	# routes is array of [action, url string after controller, extra params].
	def check_resource_routing(controller, routes, skip=[], nesting=[], resource=nil)
		resource ||= controller
		# set a prefix for nested resources
		prefix = nesting.join('s/1/')
		unless prefix.blank?
			prefix += "s/1/"
		end
		# Add params for nested resources.
		# For each 'nest', include a ":nest_id=>'1'" param.
		params = {}
		nesting.each do |param|
			params["#{param}_id".to_sym] = '1'
		end
		# Test each of the standard resource routes.
		routes.each do |pair|
			unless skip.include? pair[0]
				assert_generates("/#{prefix}#{resource}#{pair[1]}",
					{:controller=>controller,
					:action=>pair[0]}.merge(pair[2]).merge(params), {}, {},
					"Failed generation of resource route for action #{pair[0]} /#{prefix}#{resource}#{pair[1]}")
				assert_recognizes(
					{:controller=>controller,
						:action=>pair[0]}.merge(pair[2]).merge(params),
					{:path=>"/#{prefix}#{resource}#{pair[1]}", :method=>pair[3]},
					{}, "Failed to recognize resource route for path #{pair[3]}:/#{prefix}#{resource}#{pair[1]}")
			end
		end
	end
	
	# Check that ar has the expected validation errors and that the error list shows up in the view.
	def assert_validation_errors_on(ar, fields)
		validation_error_check_discrepancies(ar, fields)
		# check that the page content has the validation errors box,
		# and the expected number of error items in it
		assert_select 'div#errorExplanation' do
			assert_select 'li', :count=>ar.errors.length
		end
	end
	
	# Validate ar and verify that the expected fields have errors.
	def assert_validation_fails_for(ar, fields)
		assert !(ar.valid?), "passed validation when errors expected for fields #{fields.join(', ')}"
		validation_error_check_discrepancies(ar, fields)
	end
	
	# Checks for expected fields missing from the validation errors,
	# and unexpected fields present in the validation errors.
	# ar is an ActiveRecord object that has been validated and should have validation errors.
	# fields is an array of field (attribute) name strings that are expected to be invalid.
	def validation_error_check_discrepancies(ar, fields)
		msgs = []
		# get the list of fields that have errors (err_fields)
		err_fields = []
		ar.errors.each {|k,v| err_fields << k}
		# identify fields missing from the record’s errors 
		missing_errors = []
		fields.each do |field_name|
			missing_errors << field_name unless err_fields.include?(field_name) #if ar.errors[field_name].blank?
		end
		if missing_errors.length > 0
			msgs << "missing validation error for fields #{missing_errors.join(', ')}"
		end
		# identify unexpected fields in the record’s errors
		unexpected_errors = []
		err_fields.each do |field_name|
			unexpected_errors << field_name unless fields.include?(field_name)
		end
		if unexpected_errors.length > 0
			msgs << "unexpected errors for fields #{unexpected_errors.join(', ')}"
		end
		if msgs.length > 0
			assert false, msgs.join(".\r")
		end
	end
end
