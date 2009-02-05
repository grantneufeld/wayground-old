require 'test_helper'

class RecipientsControllerTest < ActionController::TestCase
	fixtures :email_messages, :users, :groups, :recipients, :attachments

	def setup
		@controller = RecipientsController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.resources :email_messages do |email_messages|
		#	email_messages.resources :recipients
		#end
		assert_routing_for_resources 'recipients', [], ['email_message'], {}, {}
	end
	
	
	# ACTIONS
	
end
