require 'test_helper'

class EmailAddressesControllerTest < ActionController::TestCase
	fixtures :email_addresses, :users

	def setup
		@controller = EmailAddressesController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.resources :users, :collection=>{:activate=>:get, :account=>:get} do |users|
		#	users.resources :email_addresses
		#end
		assert_routing_for_resources 'email_addresses', [], ['user'], {}, {}
	end
	
	
	# ACTIONS
	
end
