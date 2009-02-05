require 'test_helper'

class NotesControllerTest < ActionController::TestCase
	fixtures :notes, :users

	def setup
		@controller = NotesController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.resources :notes
		assert_routing_for_resources 'notes', [], [], {}, {}
	end
	
	
	# ACTIONS
	
end
