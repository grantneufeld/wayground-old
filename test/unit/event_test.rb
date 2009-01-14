require 'test_helper'

class EventTest < ActiveSupport::TestCase
	fixtures :events, :users, :schedules, :rsvps, :groups, :locations, :tags
	
	def test_associations
		assert check_associations
	end
	
	# INSTANCE METHODS
	
end
