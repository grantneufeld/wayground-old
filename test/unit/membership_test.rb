require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
	fixtures :memberships, :groups, :users, :locations
	
	def test_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	
	# METHODS
	
	
	def test_membership_find_for
		assert_equal memberships(:regular),
			Membership.find_for(memberships(:regular).group,
				memberships(:regular).user)
		assert_equal nil,
			Membership.find_for(groups(:membered_group), users(:admin))
		assert_equal nil, Membership.find_for(groups(:membered_group), nil)
		assert_equal nil, Membership.find_for(nil, users(:admin))
	end
	
	
	# Invites
	
	def test_membership_invite
		m = Membership.invite!(groups(:private_group), users(:staff),
			users(:login))
		assert m
		assert m.invited?
		assert_equal groups(:private_group), m.group
		assert_equal users(:staff), m.user
	end
	def test_membership_invite_not_permitted
		m = Membership.invite!(groups(:private_group), users(:staff),
			users(:plain))
		assert m.nil?
	end
	
	
	# Blocking
	
	def test_membership_block_member
		group = memberships(:regular).group
		user = memberships(:regular).user
		group_admin = users(:login)
		assert !(memberships(:regular).blocked?)
		m = Membership.block!(group, user, group_admin)
		assert m.blocked?
		m.clear_block!
		assert !(m.blocked?)
	end
	def test_membership_block_already_blocked
		group = memberships(:blockee).group
		user = memberships(:blockee).user
		old_date = memberships(:blockee).blocked_at
		old_blocker = memberships(:blockee).blocker
		m = Membership.block!(group, user, users(:login))
		assert_equal old_date, memberships(:blockee).blocked_at
		assert_equal old_blocker, memberships(:blockee).blocker
	end
	def test_membership_block_expire_blocked
		old_date = memberships(:blockee).block_expires_at
		assert memberships(:blockee).blocked?
		memberships(:blockee).block_expires_at = 1.day.ago
		assert !(memberships(:blockee).blocked?)
		memberships(:blockee).block_expires_at = old_date
		assert memberships(:blockee).blocked?
	end
	def test_membership_blocked
		assert memberships(:blockee).blocked?
		assert !(memberships(:expired_blockee).blocked?)
	end
	
	
	# Active
	
	def test_membership_active
		assert memberships(:private_member).active?
		assert memberships(:expired_blockee).active?
		assert !(memberships(:blockee).active?)
		assert !(memberships(:expired).active?)
		assert !(memberships(:invitee).active?)
	end
	
	
	# Expiry
	
	def test_membership_expiry
		assert memberships(:expired).expired?
		assert !(memberships(:regular).expired?)
		assert !(memberships(:blockee).expired?)
	end
	
	
end
