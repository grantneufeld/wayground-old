require 'test_helper'

class PhoneMessagesControllerTest < ActionController::TestCase
	fixtures :phone_messages, :users

	def setup
		@controller = PhoneMessagesController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.phone_messages
		assert_routing_for_resources 'phone_messages', [], [], {}, {}
	end
	
	
	# ACTIONS
	
end
