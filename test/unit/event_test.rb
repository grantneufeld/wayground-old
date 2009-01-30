require 'test_helper'

class EventTest < ActiveSupport::TestCase
	fixtures :events, :users, :schedules, :rsvps, :groups, :locations, :tags
	
	def test_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	def test_event_required_fields_validation
		e = Event.new
		assert_validation_fails_for(e, ['subpath', 'title', 'user'])
	end
	
	def test_event_subpath_validation
		e = Event.new :subpath=>'subpath', :title=>'Test'
		e.user = users(:login)
		assert_valid e
	end
	def test_event_subpath_validation_missing
		e = Event.new :title=>'Test'
		e.user = users(:login)
		assert_validation_fails_for(e, ['subpath'])
	end
	def test_event_subpath_validation_invalid
		e = Event.new :subpath=>'• This is invalid!/whatever..$', :title=>'Test'
		e.user = users(:login)
		assert_validation_fails_for(e, ['subpath'])
	end
	def test_event_subpath_validation_duplicate
		e = Event.new :subpath=>'event1', :title=>'Test'
		e.user = users(:login)
		assert_validation_fails_for(e, ['subpath'])
	end
	
	def test_event_title_validation_missing
		e = Event.new :subpath=>'subpath'
		e.user = users(:login)
		assert_validation_fails_for(e, ['title'])
	end
	
	def test_event_content_type_validation
		%w(text/plain text/html text/wayground).each do |content_type|
			e = Event.new(:subpath=>'subpath', :title=>'Test',
				:content_type=>content_type)
			e.user = users(:login)
			assert_valid e #, "expected content_type of ‘#{content_type}’ to be valid"
		end
	end
	def test_event_content_type_validation_missing_for_content
		# content_type gets set to text/plain if content_type.blank? and !content.blank?
		e = Event.new :subpath=>'subpath', :title=>'Test', :content=>'Test'
		e.user = users(:login)
		e.valid?
		assert_equal 'text/plain', e.content_type
	end
	def test_event_content_type_validation_invalid
		e = Event.new :subpath=>'subpath', :title=>'Test',
			:content_type=>'application/pdf'
		e.user = users(:login)
		assert_validation_fails_for(e, ['content_type'])
	end
	
	def test_event_user_validation_missing
		e = Event.new :subpath=>'subpath', :title=>'Test'
		assert_validation_fails_for(e, ['user'])
	end
	
	
	# CLASS METHODS
	
	def test_event_search_conditions
		# no conditions
		assert_equal nil, Event.search_conditions
	end
	def test_event_search_conditions_custom
		assert_equal ['a AND b',1,2], Event.search_conditions({}, ['a','b'], [1,2])
	end
	def test_event_search_conditions_keyword
		assert_equal([
			'(events.title LIKE ? OR events.description LIKE ? OR events.content LIKE ?)',
			'%keyword%', '%keyword%', '%keyword%'],
			Event.search_conditions({:key=>'keyword'}))
	end
	def test_event_search_conditions_restrict_upcoming
		assert_equal(['(events.next_at IS NOT NULL)'],
			Event.search_conditions({:restrict=>:upcoming}))
	end
	def test_event_search_conditions_restrict_past
		assert_equal(['(events.next_at IS NULL)'],
			Event.search_conditions({:restrict=>:past}))
	end
	def test_event_search_conditions_all_options
		# keyword search and custom conditions
		assert_equal([
			'a AND b AND (events.title LIKE ? OR events.description LIKE ? OR events.content LIKE ?) AND (events.next_at IS NOT NULL)',
			1, 2, '%keyword%', '%keyword%', '%keyword%'],
			Event.search_conditions({:key=>'keyword', :restrict=>:upcoming},
				['a','b'], [1,2]))
	end
	
	
	def test_event_update_next_at_for_all_events
		assert Event.find(:all, :conditions=>'events.next_at < NOW()').size > 0,
			'expected at least one expired event with a next_at attribute needing updating'
		Event.update_next_at_for_all_events
		assert_equal [], Event.find(:all, :conditions=>'events.next_at < NOW()')
	end
	
	
	# INSTANCE METHODS
	
	def test_event_calculate_next_at
		assert_equal schedules(:one).start_at, events(:one).calculate_next_at
	end
	def test_event_calculate_next_at
		assert_nil events(:one).calculate_next_at(1.year.from_now)
	end
	
	def test_event_css_class
		assert_equal 'event', events(:one).css_class
	end
	def test_event_css_class_prefix
		assert_equal 'dir-event', events(:two).css_class('dir-')
	end
end
