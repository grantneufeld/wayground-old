require 'test_helper'

class LocationTest < ActiveSupport::TestCase
	fixtures :locations, :users
	
	def test_location_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	def test_location_valid_url
		l = Location.new({:url=>'http://wayground.ca/'})
		assert l.valid?
	end
	def test_location_invalid_url
		l = Location.new({:url=>'wayground.ca'})
		assert !(l.valid?)
		l = Location.new({:url=>'http:// wayground.ca/'})
		assert !(l.valid?)
	end
	
	def test_location_valid_email
		l = Location.new({:email=>'test@wayground.ca'})
		assert l.valid?
	end
	def test_location_invalid_email
		l = Location.new({:email=>'invalid'})
		assert !(l.valid?)
		l = Location.new({:email=>'invalid@email'})
		assert !(l.valid?)
		l = Location.new({:email=>'invalid@fake.email.domain.tld'})
		assert !(l.valid?)
		l = Location.new({:email=>'invalid chars@wayground.ca'})
		assert !(l.valid?)
	end
	
	
	# CLASS METHODS
	
	def test_location_phone_options
		opts = [['',''], ['home','h'], ['work','w'], ['cell','c'], ['fax','f']]
		assert_equal opts, Location.phone_options
	end
end
