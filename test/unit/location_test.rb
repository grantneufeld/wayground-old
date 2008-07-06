require 'test_helper'

class LocationTest < ActiveSupport::TestCase
	fixtures :locations, :users
	
	def test_location_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	# TODO test location validations
	
end
