require 'test_helper'

class AttachmentsControllerTest < ActionController::TestCase
	fixtures :email_messages, :users, :groups, :recipients, :attachments

	def setup
		@controller = AttachmentsController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.resources :email_messages do |email_messages|
		#	email_messages.resources :attachments
		#end
		assert_routing_for_resources 'attachments', [], ['email_message'], {}, {}
	end
	
	
	# ACTIONS
	
end
