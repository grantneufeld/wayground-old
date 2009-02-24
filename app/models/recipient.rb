class Recipient < ActiveRecord::Base
	attr_accessible :email_message_id, :email_address_id, :email, :name #, :field
	
	belongs_to :email_message
	belongs_to :email_address
	
	validates_presence_of :email_message
	validates_presence_of :email_address
	validates_uniqueness_of :email_address_id, :scope=>:email_message_id
	#validates_presence_of :email
	#validates_format_of :email,
	#	:with=>/\A(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?\z/i,
	#	:message=>"invalid email", :allow_nil=>true
	#validates_uniqueness_of :email, :scope=>:email_message_id
	
	def to_s
		email_address.to_s
	end
end
