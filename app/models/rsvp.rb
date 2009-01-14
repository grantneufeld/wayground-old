class Rsvp < ActiveRecord::Base
	attr_accessible :rsvp
	
	validates_inclusion_of :rsvp, :in=>%w(yes no maybe invited),
		:message=>'must be “yes”, “no”, “maybe”, “invited” or blank'
	
	belongs_to :schedule
	belongs_to :user
end
