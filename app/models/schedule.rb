class Schedule < ActiveRecord::Base
	attr_accessible :start_at, :end_at, :info,
		:recur, :unit, :interval, :ordinal, :recur_day, :recur_month
	
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
			(p.recur == 'relative' and %w(week month year).include?(p.unit)) or (p.recur == 'fixed' and p.unit == 'week')
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
	has_many :rsvps
	has_many :locations
end
