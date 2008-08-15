require 'test_helper'

class MembershipsControllerTest < ActionController::TestCase
	fixtures :memberships, :groups, :users, :locations

	def setup
		@controller = MembershipsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_memberships_resource_routing
		# map.resources :memberships
		assert_routing_for_resources 'memberships', [], [], {}
	end
	
end
