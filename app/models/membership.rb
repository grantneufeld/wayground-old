class Membership < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :position, :is_admin, :can_add_event, :can_invite,
		:can_moderate, :can_manage_members, :expires_at, :invited_at,
		:blocked_at, :block_expires_at, :title
	
	validates_presence_of :group
	validates_presence_of :user
	
	validates_uniqueness_of :user_id, :scope=>:group_id
	
	belongs_to :group
	belongs_to :user
	belongs_to :location
	belongs_to :inviter, :class_name=>"User"
	belongs_to :blocker, :class_name=>"User"
	
	
	# CLASS METHODS
	
	
	def self.find_for(group, user)
		if group and user
			group.memberships.find(:first,
				:conditions=>['memberships.user_id = ?', user.id])
		else
			nil
		end
	end
	
	def self.invite!(group, user, inviter)
		# validate that the inviter has authority to invite to this group
		inviter_membership = Membership.find_for(group, inviter)
		if inviter_membership and inviter_membership.active? and (inviter_membership.is_admin or inviter_membership.can_invite)
			# determine if user is already a member or invited
			existing_membership = Membership.find_for(group, user)
			if existing_membership
				nil
				# TODO: would potentially be useful to have some way of notifying the inviter that the user was already invited or a member
			else
				m = self.new
				m.group = group
				m.user = user
				m.invited_at = Time.current
				m.inviter = inviter
				m.save!
				m
			end
		else
			nil
			# TODO: would potentially be useful to have some way of notifying the inviter that they don’t have permission to invite to the group
		end
	end
	
	def self.block!(group, user, blocker, expires=nil)
		# determine if user is already a member or invited
		m = Membership.find_for(group, user)
		unless m
			m = self.new
			m.group = group
			m.user = user
		end
		# block the membership
		m.block!(blocker, expires)
	end
	
	
	# INSTANCE METHODS
	
	
	def active?
		!(expired?) && !(invited?) && !(blocked?)
	end
	
	def blocked?
		
		!(blocked_at.nil?) && blocked_at <= Time.current && (block_expires_at.nil? || block_expires_at > Time.current)
	end
	def block!(blocker, expires=nil)
		
		blocker_membership = Membership.find_for(group, blocker)
		if blocker_membership and blocker_membership.active? and (blocker_membership.is_admin or blocker_membership.can_manage_members)
			# check if membership is already blocked
			unless blocked_at and (!(block_expires_at) or block_expires_at >= Time.current)
				# wipe out permissions
				self.is_admin = false
				self.can_add_event = false
				self.can_invite = false
				self.can_moderate = false
				self.can_manage_members = false
				# clear any outstanding invitation
				self.invited_at = nil
				self.inviter = nil
				# block the user
				self.blocked_at = Time.current
				self.block_expires_at = expires
				self.blocker = blocker
				# save and return the blocked membership
				save!
			end
			self
		else
			# blocker doesn’t have permission to block for the group
			nil
		end
	end
	def clear_block!
		self.blocked_at = nil
		self.block_expires_at = nil
		self.blocker = nil
		save!
		self
	end
	
	def expired?
		!(expires_at.nil?) && expires_at <= Time.current
	end
	
	def invited?
		!(invited_at.nil?)
	end
end
