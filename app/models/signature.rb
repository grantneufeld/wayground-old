class Signature < ActiveRecord::Base
	attr_accessible :is_public, :allow_followup, :name, :email,
		:phone, :address, :city, :province, :country, :postal_code,
		:custom_field, :comment
	
	belongs_to :petition
	belongs_to :user
	
	validates_presence_of :petition
	validates_presence_of :name
	validates_presence_of :email
	validates_uniqueness_of :user_id, :scope=>:petition_id,
		:message=>'you have already signed this petition',
		:if=>Proc.new {|sig| !(sig.user.nil?)}
	validates_uniqueness_of :email, :scope=>:petition_id,
		:message=>'invalid signature'
end
