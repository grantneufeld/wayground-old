require 'test_helper'

class SchedulesControllerTest < ActionController::TestCase
	fixtures :events, :users, :schedules, :rsvps, :groups, :locations, :tags

	def setup
		@controller = SchedulesController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	def test_schedules_resource_routing
		#map.resources :events do |events|
		#	events.resources :schedules do |schedules|
		#		schedules.resources :rsvps
		#	end
		#end
		assert_routing_for_resources 'schedules', [], ['event'], {}, {}
	end
end
