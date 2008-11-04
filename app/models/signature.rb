class Signature < ActiveRecord::Base
	attr_accessible :is_public, :allow_followup, :name, :email,
		:phone, :address, :city, :province, :country, :postal_code,
		:custom_field, :comment
	
	belongs_to :petition
	belongs_to :user
	
	validates_presence_of :petition
	validates_presence_of :name
	validates_presence_of :email
	validates_format_of :email,
		:with=>/\A(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?\z/i,
		:message=>"invalid email", :allow_nil=>true
	validates_uniqueness_of :user_id, :scope=>:petition_id,
		:message=>'you have already signed this petition',
		:if=>Proc.new {|sig| !(sig.user.nil?)}
	validates_uniqueness_of :email, :scope=>:petition_id,
		:message=>'invalid signature'
	validate :valid_email?
	
	include EmailHelper # email validation
	# based on http://lindsaar.net/2008/4/15/tip-6-validating-the-domain-of-an-email-address-with-ruby-on-rails
	def valid_email?
		unless email.blank?
			err = domain_error(domain_of(email))
			errors.add(:email, err) unless err.blank?
		end
	end
	
end
