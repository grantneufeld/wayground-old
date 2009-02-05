class Recipient < ActiveRecord::Base
	attr_accessible :email_message_id, :user_id, :to
	
	belongs_to :email_message
	belongs_to :user
	
	validates_presence_of :email_message
	validates_presence_of :user
	validates_presence_of :to
	validates_uniqueness_of :user, :scope=>:email_message
end
