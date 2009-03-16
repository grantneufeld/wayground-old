class Location < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :name, :address, :address2, :city, :province, :country,
		:postal, :longitude, :latitude, :url,
		:phone1_type, :phone1, :phone2_type, :phone2, :phone3_type, :phone3
	
	validates_format_of :url, :allow_nil=>true,
		:with=>/\A(https?:\/\/[^ \t\r\n]+)?\z/,
		:message=>'must be a valid URL (starting with ‘http://’)'
	
	# locatable models may include User, Schedule, Group, Candidate, Campaign
	belongs_to :locatable, :polymorphic=>true
	# TODO: make locations reusable so the data doesn’t have to be duplicated when multiple items are at the same location.

	has_many :memberships, :dependent=>:nullify
	
	
	# phone_type options for form select fields
	def self.phone_options
		[['',''], ['home','h'], ['work','w'], ['cell','c'], ['fax','f']]
	end
	
	# required instance methods for Contactable items
	def email
		nil
	end
	def email_addresses
		return []
	end
	def locations
		return [self]
	end
	# name returned by attribute
end
