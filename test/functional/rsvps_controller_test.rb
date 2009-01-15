require 'test_helper'

class RsvpsControllerTest < ActionController::TestCase
	fixtures :events, :users, :schedules, :rsvps, :groups, :locations, :tags

	def setup
		@controller = RsvpsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	def test_rsvps_resource_routing
		#map.resources :events do |events|
		#	events.resources :schedules do |schedules|
		#		schedules.resources :rsvps
		#	end
		#end
		assert_routing_for_resources 'rsvps', [], ['event', 'schedule'], {}, {}
	end
end
