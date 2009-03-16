require 'test_helper'

class LocationTest < ActiveSupport::TestCase
	fixtures :locations, :users
	
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	test "valid url" do
		l = Location.new({:url=>'http://wayground.ca/'})
		assert l.valid?
	end
	test "invalid url" do
		l = Location.new({:url=>'wayground.ca'})
		assert !(l.valid?)
		l = Location.new({:url=>'http:// wayground.ca/'})
		assert !(l.valid?)
	end
	
	
	# CLASS METHODS
	
	test "phone options" do
		opts = [['',''], ['home','h'], ['work','w'], ['cell','c'], ['fax','f']]
		assert_equal opts, Location.phone_options
	end
	
	test "email" do
		assert_nil locations(:one).email
	end
	
	test "email addresses" do
		assert_equal [], locations(:one).email_addresses
	end
	
	test "locations" do
		assert_equal [locations(:one)], locations(:one).locations
	end
end
