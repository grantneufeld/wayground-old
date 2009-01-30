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
	def test_schedule_validation_presence_of_recur_day
		s = Schedule.new :start_at=>Time.now, :recur=>'relative', :unit=>'week',
			:interval=>1, :recur_day=>'Sunday'
		assert_valid s
	end
	def test_schedule_validation_presence_of_recur_day_missing
		s = Schedule.new :start_at=>Time.now, :recur=>'relative', :unit=>'week',
			:interval=>1
		assert_validation_fails_for(s, ['recur_day'])
	end
	
	
	# INSTANCE METHODS
	
	def test_schedule_track_error
		
	end
	
	def test_schedule_clear_error
		s = Schedule.new :start_at=>Time.now
		s.clear_error(:start_at)
		assert_valid s
	end
	def test_schedule_clear_error_invalid
		s = Schedule.new :start_at=>Time.now, :end_at=>'invalid'
		assert_validation_fails_for(s, ['end_at'])
		s.clear_error(:end_at)
		assert_valid s
	end
	
	def test_schedule_start_at_from_string
		s = Schedule.new :start_at=>'January 1, 2009 4:32 pm'
		assert_valid s
		assert_equal Time.parse('2009-01-01 16:32'), s.start_at
	end
	def test_schedule_start_at_from_string_invalid
		s = Schedule.new :start_at=>'fail'
		assert_validation_fails_for(s, ['start_at'])
	end
	
	def test_schedule_end_at_assignment
		t = Time.now
		s = Schedule.new :start_at=>Time.now, :end_at=>t
		assert_equal t, s.end_at
		assert_valid s
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
	def test_schedule_next_at_with_recur
		s = Schedule.new :start_at=>1.day.ago, :recur=>'relative', :unit=>'week',
		 	:interval=>1, :recur_day=>'Sunday'
		# TODO: Handle actual recurrence calculations
		assert_nil s.next_at
	end
end
