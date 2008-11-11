require 'test_helper'

class SignaturesControllerTest < ActionController::TestCase
	fixtures :petitions, :users, :signatures

	def setup
		@controller = SignaturesController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	def test_signatures_resource_routing
		#map.resources :petitions do |petitions|
		#	petitions.resources :signatures, :member=>{:confirm=>:get}
		#end
		assert_routing_for_resources 'signatures', [], ['petition'], {},
			{:confirm=>:get}
	end
end
