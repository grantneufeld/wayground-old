require 'test_helper'

class Membership < ActiveRecord::Base
	# provide access to the @track_errors instance var for testing
	def track_errors
		@track_errors
	end
end

class MembershipTest < ActiveSupport::TestCase
	fixtures :memberships, :groups, :users, :locations
	
	def test_membership_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	def test_membership_validation_minimum_to_pass
		m = Membership.new
		m.group = groups(:update_group)
		m.user = users(:regular)
		assert_valid m
	end
	
	def test_membership_validation_invalid_expires_at
		m = Membership.new :expires_at=>'invalid'
		m.group = groups(:update_group)
		m.user = users(:regular)
		assert_validation_fails_for(m, ['expires_at'])
	end
	
	# CLASS METHODS
	
	def test_membership_find_for
		assert_equal memberships(:regular),
			Membership.find_for(memberships(:regular).group,
				memberships(:regular).user)
		assert_equal nil,
			Membership.find_for(groups(:membered_group), users(:admin))
		assert_equal nil, Membership.find_for(groups(:membered_group), nil)
		assert_equal nil, Membership.find_for(nil, users(:admin))
	end
	
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
		assert_nil m
	end
	def test_membership_invite_existing_member
		m = Membership.invite!(groups(:private_group), users(:regular),
			users(:login))
		assert_nil m
	end
	
	def test_membership_block_member
		group = memberships(:regular).group
		user = memberships(:regular).user
		group_admin = users(:login)
		assert !(memberships(:regular).blocked?)
		m = Membership.block!(group, user, group_admin)
		assert m.blocked?
		m.clear_block!
	end
	def test_membership_block_non_member
		group_admin = users(:login)
		m = Membership.block!(groups(:membered_group), users(:someone), group_admin)
		assert m.blocked?
		m.clear_block!
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
	
	
	# INSTANCE METHODS
	
	def test_membership_track_error
		m = Membership.new
		assert_nil m.track_errors
		m.track_error('title', 'fail')
		assert_equal({'title'=>'fail'}, m.track_errors)
	end
	
	def test_membership_clear_error
		m = Membership.new
		m.track_error('title', 'fail')
		m.clear_error('title')
		assert_equal({}, m.track_errors)
	end
	def test_membership_clear_error_no_errors
		m = Membership.new
		m.clear_error('title')
		assert_nil m.track_errors
	end
	
	def test_membership_expiry
		assert memberships(:expired).expired?
		assert !(memberships(:regular).expired?)
		assert !(memberships(:blockee).expired?)
	end
	
	def test_membership_expires_at_assignment
		t = 1.day.from_now
		memberships(:update_membership).expires_at = t
		assert_equal t, memberships(:update_membership).expires_at
	end
	def test_membership_expires_at_assignment_string
		# ? this may need to be set to the current system’s time zone or the config.time_zone
		Time.zone = 'Mountain Time (US & Canada)'
		t = 1.day.from_now
		t -= t.sec # since :form_datetime omits seconds
		memberships(:update_membership).expires_at = t.to_s(:form_datetime)
		assert_equal t.utc.to_s(:db), memberships(:update_membership).expires_at.utc.to_s(:db)
	end
	def test_membership_expires_at_assignment_invalid
		memberships(:update_membership).expires_at = 'invalid'
		assert memberships(:update_membership).track_errors['expires_at']
	end
	
	def test_membership_active
		assert memberships(:private_member).active?
		assert memberships(:expired_blockee).active?
		assert !(memberships(:blockee).active?)
		assert !(memberships(:expired).active?)
		assert !(memberships(:invitee).active?)
	end
	
	def test_membership_blocked
		
	end
	
	def test_membership_block
		group_admin = users(:login)
		memberships(:regular).block!(group_admin)
		assert memberships(:regular).blocked?
		memberships(:regular).clear_block!
	end
	def test_membership_block_fail_non_admin
		group_admin = users(:another)
		memberships(:regular).block!(group_admin)
		assert !(memberships(:regular).blocked?)
	end
	
	def test_membership_clear_block
		
	end
	
	def test_membership_expired
		
	end
	
	def test_membership_invited
		
	end
	
	def test_membership_has_access_to
		assert memberships(:privateowner).has_access_to?(:member_list)
		assert memberships(:privateowner).has_access_to?(:manage_members)
		assert memberships(:privateowner).has_access_to?(:inviting)
		assert memberships(:privateowner).has_access_to?(:admin)
		assert !(memberships(:private_member).has_access_to?(:member_list))
		assert !(memberships(:private_member).has_access_to?(:manage_members))
		assert !(memberships(:private_member).has_access_to?(:inviting))
		assert memberships(:regular).has_access_to?(:member_list)
		assert !(memberships(:regular).has_access_to?(:manage_members))
		assert !(memberships(:regular).has_access_to?(:inviting))
		
		assert_raise(Wayground::UnrecognizedParameter) do
			memberships(:private_member).has_access_to?('member_list')
		end
		assert_raise(Wayground::UnrecognizedParameter) do
			memberships(:private_member).has_access_to?(:invalid_param)
		end
	end
	def test_membership_has_access_to_array
		assert !(memberships(:private_member).has_access_to?(
			[:member_list, :manage_members, :inviting]))
		assert memberships(:regular).has_access_to?(
			[:member_list, :manage_members, :inviting])
	end
	
	def test_membership_email
		user = User.new(:email=>'test@wayground.ca')
		membership = Membership.new
		membership.group = groups(:one)
		membership.user = user
		assert_equal 'test@wayground.ca', membership.email
	end
	def test_membership_email_from_location
		user = User.new(:email=>'user-test@wayground.ca')
		location = Location.new(:email=>'location-test@wayground.ca')
		membership = Membership.new
		membership.group = groups(:one)
		membership.user = user
		membership.location = location
		assert_equal 'location-test@wayground.ca', membership.email
	end
end
