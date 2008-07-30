require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
	fixtures :groups, :users, :locations

	def setup
		@controller = GroupsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_groups_resource_routing
		# map.resources :groups
		assert_routing_for_resources 'groups', [], [], {}
	end
	
	# INDEX (LIST)

	# SHOW

	# NEW

	# CREATE
	# EDIT
	# UPDATE
	# DELETE
end
