module Wayground
	# A parameter does not match any known option.
	class UnrecognizedParameter < Exception; end
	# The User cannot be added to the Group
	class CannotAddUserMembership < Exception; end
end

class Membership < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :position, :is_admin, :can_add_event, :can_invite,
		:can_moderate, :can_manage_members, :expires_at, :invited_at,
		:blocked_at, :block_expires_at, :title
	
	belongs_to :group
	belongs_to :user
	belongs_to :email_address # if nil, use the user’s default address
	belongs_to :location
	belongs_to :inviter, :class_name=>"User"
	belongs_to :blocker, :class_name=>"User"
	
	validates_presence_of :group
	# requires either a User or EmailAddress
	validates_presence_of :user, :if=> Proc.new {|m| m.email_address.nil?}
	validates_presence_of :email_address, :if=> Proc.new {|m| m.user.nil?}
	
	validates_uniqueness_of :email_address_id, :scope=>:group_id,
		:unless=> Proc.new {|m| m.email_address.nil?}
	#validates_uniqueness_of :user_id, :scope=>[:group_id, :email_address_id]
	
	
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
		
		if inviter_membership.has_access_to?(:inviting)
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
	
	
	def validate
		if @track_errors
			@track_errors.each do |k,v|
				errors.add(k,v)
			end
			@track_errors = {}
		end
	end
	
	# there ought to be a Rails way to add an error to a field before validation
	# instead of this approach that feels a bit hacky
	def track_error(field, msg)
		@track_errors ||= {}
		@track_errors[field.to_s] = msg
	end
	def clear_error(field)
		if @track_errors
			@track_errors.delete(field.to_s)
		end
	end
	
	def expires_at=(t)
		if t.is_a? String and !(t.blank?)
			t.gsub! ',', ' '
			s = Chronic.parse(t)
			s = s.utc if s
			s ||= DateTime.parse(t) rescue ArgumentError
			if s
				write_attribute('expires_at', s)
			else
				track_error('expires_at',
					'not a recognized text format for a date and time')
			end
		else
			write_attribute('expires_at', t)
		end
	end
	
	def active?
		!(id.nil?) && (id > 0) && !(group.nil?) && !(expired?) && !(invited?) && !(blocked?) && !(user.nil? and email_address.nil?) 
	end
	
	def make_active!
		self.invited_at = nil
		self.expires_at = nil if expired?
		clear_block! # saves
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
		!(self.expires_at.nil?) && (self.expires_at <= Time.current)
	end
	
	def invited?
		!(self.invited_at.nil?)
	end
	
	# s - a symbol or an array of symbols (which any of which matching will return true)
	def has_access_to?(s)
		if s.is_a? Symbol
			s = [s]
		end
		has_access = (self.is_admin or self.user == self.group.owner)
		unless has_access
			s.each do |sym|
				case sym
				when :self_join
					has_access ||= (!(active?) and (invited? or !(group.is_invite_only)))
				when :member_list
					has_access ||= (active? and (self.can_manage_members or self.group.is_members_visible))
				when :manage_members
					has_access ||= (active? and self.can_manage_members)
				when :inviting
					has_access ||= (active? and self.can_invite)
				when :admin
					# covered by default has_access set when user is_admin or group.owner
				else
					raise Wayground::UnrecognizedParameter
				end
			end
		end
		has_access
	end
	
	def email
		if self.email_address
			self.email_address.email
		else
			self.user.email
		end
	end
	
	def name
		if self.user
			self.user.nickname
		else
			self.email_address.name
		end
	end
	
	def member_name(user=nil)
		name = "member #{self.id}"
		unless user.nil?
			if self.user
				name = self.user.display_name_for_admin(
					self.group.has_access_to?(:admin, user)
				)
			elsif self.group.has_access_to?(:admin, user) and !(self.email_address.name.blank?)
				name = self.email_address.name
			end
		end
		name
	end
	
	def link
		if self.user
			self.user.link
		else
			self.email_address.link
		end
	end
end
