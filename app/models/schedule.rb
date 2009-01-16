require 'chronic'

class Schedule < ActiveRecord::Base
	attr_accessible :start_at, :end_at, :info,
		:recur, :unit, :interval, :ordinal, :recur_day, :recur_month
	
	validates_presence_of :start_at
	# TODO: figure out what I meant by “contained” for schedule recurrence???
	validates_inclusion_of :recur, :in=>%w(relative fixed contained),
		:allow_nil=>true, :allow_blank=>true,
		:message=>'must be “relative”, “fixed”, “contained” or blank'
	validates_presence_of :unit, :unless=>Proc.new {|p| p.recur.blank?}
	validates_inclusion_of :unit,
		:in=>%w(second minute hour day week month year),
		:allow_nil=>true, :allow_blank=>true,
		:message=>'must be “second”, “minute”, “hour”, “day”, “week”, “month”, “year” or blank'
	validates_presence_of :interval, :unless=>Proc.new {|p| p.recur.blank?}
	validates_numericality_of :interval, :only_integer=>true, :greater_than=>0,
		:allow_nil=>true
	validates_presence_of :ordinal,
		:if=>Proc.new {|p| !(p.recur.blank?) and %w(month year).include?(p.unit)},
		:message=>'required when the recurrence unit is months or years'
	validates_numericality_of :ordinal, :only_integer=>true, :allow_nil=>true
	validates_presence_of :recur_day,
		:if=>Proc.new {|p|
			((p.recur == 'relative' and %w(week month year).include?(p.unit)) or
			(p.recur == 'fixed' and p.unit == 'week'))
		},
		:message=>'required when the recurrence unit is weeks, months or years'
	validates_inclusion_of :recur_day,
		:in=>%w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday),
		:allow_nil=>true, :allow_blank=>true,
		:message=>'must be the name of a day of the week (e.g., “Friday”) or blank'
	validates_presence_of :recur_month,
		:if=>Proc.new {|p| !(p.recur.blank?) and p.unit == 'year' },
		:message=>'required when the recurrence unit is years'
	validates_inclusion_of :recur_month,
		:in=>%w(January February March April May June July August September October November December),
		:allow_nil=>true, :allow_blank=>true,
		:message=>'must be the name of a month (e.g., “January”) or blank'
	
	belongs_to :event
	has_many :rsvps, :order=>'rsvps.position, rsvps.confirmed_at'
	has_many :locations, :as=>:locatable, :order=>'locations.position'
	
	def validate
		if @track_errors
			@track_errors.each do |k,v|
				errors.add(k,v)
			end
			@track_errors = {}
		end
	end
	
	# there ought to be a Rails way to add an error to a field before validation
	# instead of this approach that feels a bit hacky
	def track_error(field, msg)
		@track_errors ||= {}
		@track_errors[field] = msg
	end
	def clear_error(field)
		if @track_errors
			@track_errors[field].delete
		end
	end
	
	def start_at=(t)
		if t.is_a? String
			t.gsub! ',', ' '
			s = Chronic.parse(t)
			s = s.utc if s
			s ||= DateTime.parse(t) rescue ArgumentError
			if s
				write_attribute('start_at', s)
			else
				track_error('start_at',
					'not a recognized text format for a date and time')
			end
		else
			write_attribute('start_at', t)
		end
	end
	
	def end_at=(t)
		if t.is_a? String
			t.gsub! ',', ' '
			s = Chronic.parse(t)
			s = s.utc if s
			s ||= DateTime.parse(t) rescue ArgumentError
			if s
				write_attribute('end_at', s)
			else
				track_error('end_at', 'not a recognized text format for a date and time')
			end
		else
			write_attribute('end_at', t)
		end
	end
	
	def next_at(relative_to=Time.now)
		if !(start_at.nil?) and start_at < relative_to
			if recur.blank?
				nil
			else
				# TODO: ••• calculate next datetime for the schedule
				nil
			end
		else
			start_at
		end
	end
end
