class Attachment < ActiveRecord::Base
	attr_accessible :email_message_id, :document_id, :position
	
	belongs_to :email_message
	belongs_to :document
	
	validates_presence_of :email_message
	validates_presence_of :document
	validates_uniqueness_of :document, :scope=>:email_message
end
