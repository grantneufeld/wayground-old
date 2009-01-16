class Location < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :name, :address, :address2, :city, :province, :country,
		:postal, :longitude, :latitude, :url, :email,
		:phone1_type, :phone1, :phone2_type, :phone2, :phone3_type, :phone3
	
	has_many :memberships, :dependent=>:nullify
	
	validates_format_of :url, :allow_nil=>true,
		:with=>/\A(https?:\/\/[^ \t\r\n]+)?\z/,
		:message=>'must be a valid URL (starting with ‘http://’)'
	validates_format_of :email, :allow_nil=>true,
		:with=>/\A(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?\z/i,
		:message=>'invalid email'
	validate :valid_email?
	
	# locatable models may include User, Schedule, Group, Candidate, Campaign
	belongs_to :locatable, :polymorphic=>true
	# TODO: make locations reusable so the data doesn’t have to be duplicated when multiple items are at the same location.

	include EmailHelper # email validation
	
	
	# phone_type options for form select fields
	def self.phone_options
		[['',''], ['home','h'], ['work','w'], ['cell','c'], ['fax','f']]
	end
	
	
	# based on http://lindsaar.net/2008/4/15/tip-6-validating-the-domain-of-an-email-address-with-ruby-on-rails
	def valid_email?
		unless email.blank?
			err = domain_error(domain_of(email))
			errors.add(:email, err) unless err.blank?
		end
	end
end
