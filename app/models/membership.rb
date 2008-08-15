class Membership < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :position, :is_admin, :can_add_event, :can_invite,
		:can_moderate, :can_manage_members, :expires_at, :invited_at,
		:blocked_at, :block_expires_at, :title
	
	validates_presence_of :group
	validates_presence_of :user
	
	belongs_to :group
	belongs_to :user
	belongs_to :location
	belongs_to :inviter, :class_name=>"User"
	belongs_to :blocker, :class_name=>"User"
end
