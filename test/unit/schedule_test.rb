require 'test_helper'

class ScheduleTest < ActiveSupport::TestCase
	fixtures :events, :users, :schedules, :rsvps, :groups, :locations, :tags
	
	def test_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	def test_schedule_validation_required_fields
		s = Schedule.new :start_at=>Time.now
		assert_valid s
	end
	def test_schedule_validation_required_fields_missing
		s = Schedule.new
		assert_validation_fails_for(s, ['start_at'])
	end
	
	
	# INSTANCE METHODS
	
	def test_schedule_start_at_from_string
		s = Schedule.new :start_at=>'January 1, 2009 4:32 pm'
		assert_valid s
	end
	def test_schedule_start_at_from_string_invalid
		s = Schedule.new :start_at=>'fail'
		assert_validation_fails_for(s, ['start_at'])
	end
	
	def test_schedule_end_at_from_string
		s = Schedule.new :start_at=>Time.now, :end_at=>'January 1, 2009 4:32 pm'
		assert_valid s
	end
	def test_schedule_end_at_from_string_invalid
		s = Schedule.new :start_at=>Time.now, :end_at=>'fail'
		assert_validation_fails_for(s, ['end_at'])
	end
	
	def test_schedule_next_at_future
		assert_equal schedules(:one).start_at, schedules(:one).next_at
	end
	def test_schedule_next_at_past
		assert_nil schedules(:one).next_at(1.year.from_now)
	end
end
