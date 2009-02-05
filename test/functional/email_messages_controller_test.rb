require 'test_helper'

class EmailMessagesControllerTest < ActionController::TestCase
	fixtures :email_messages, :users, :groups, :recipients, :attachments

	def setup
		@controller = EmailMessagesController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.resources :email_messages
		assert_routing_for_resources 'email_messages', [], [], {}, {}
		#map.resources(:groups …) do |groups|
		#	groups.resources :emails, :controller=>:email_messages
		assert_routing_for_resources 'email_messages', [], ['group'], {}, {}, 'emails'
	end
	
	
	# ACTIONS
	
end
