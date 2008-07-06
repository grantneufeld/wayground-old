require 'test_helper'

class LocationsControllerTest < ActionController::TestCase
	fixtures :locations, :users

	def setup
		@controller = PagesController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_location_resource_routing
		# map.resources :locations
		assert_routing_for_resources 'locations', [], [], {}
	end
	
end
