require 'test_helper'

class GroupTest < ActiveSupport::TestCase
	fixtures :groups, :users, :memberships, :locations, :email_messages
	
	def test_associations
		assert check_associations
		
		#belongs_to :creator
		assert_equal users(:admin), groups(:one).creator
		#belongs_to :owner
		assert_equal users(:admin), groups(:one).owner
		
		#belongs_to :parent
		assert_equal groups(:one), groups(:two).parent
		
		#has_many :children
		assert_equal 2, groups(:one).children.size
		assert_equal groups(:three), groups(:one).children[0]
	end
	
	
	# VALIDATIONS
	
	def test_group_valid_required_fields
		g = Group.new({:name=>'Validation', :subpath=>'validation'})
		g.creator = g.owner = users(:admin)
		assert g.valid?
	end
	def test_group_invalid_required_fields
		g = Group.new()
		assert !(g.valid?)
		g = Group.new({:name=>'Validation'})
		assert !(g.valid?)
		g = Group.new({:subpath=>'validation'})
		assert !(g.valid?)
	end
	
	def test_group_valid_url
		g = Group.new({:name=>'Validation', :subpath=>'validation',
			:url=>'http://wayground.ca/'})
		g.creator = g.owner = users(:admin)
		assert g.valid?
	end
	def test_group_invalid_url
		g = Group.new({:name=>'Validation', :subpath=>'validation',
			:url=>'wayground.ca'})
		assert !(g.valid?)
		g = Group.new({:name=>'Validation', :subpath=>'validation',
			:url=>'http:// wayground.ca/'})
		assert !(g.valid?)
	end
	
	def test_group_valid_subpath
		g = Group.new({:name=>'Validation', :subpath=>'validation',
			:subpath=>'valid-subpath'})
		g.creator = g.owner = users(:admin)
		assert g.valid?
	end
	def test_group_invalid_subpath
		g = Group.new({:name=>'Validation', :subpath=>'validation',
			:subpath=>'invalid subpath'})
		assert !(g.valid?)
		g = Group.new({:name=>'Validation', :subpath=>'validation',
			:subpath=>'/invalidsubpath'})
		assert !(g.valid?)
		g = Group.new({:name=>'Validation', :subpath=>'validation',
			:subpath=>'invalid.subpath'})
		assert !(g.valid?)
		g = Group.new({:name=>'Validation', :subpath=>'validation',
			:subpath=>'-invalid-subpath'})
		assert !(g.valid?)
	end
	
	
	# CLASS METHODS
	
	def test_group_default_include
		assert_nil Group.default_include
	end
	
	def test_group_default_order
		assert_equal 'groups.name', Group.default_order
	end
	def test_group_default_order_recent
		assert_equal 'groups.updated_at DESC, groups.name',
			Group.default_order({:recent=>true})
	end
	
	def test_group_search_conditions
		assert_equal ['(groups.is_visible = 1)'], Group.search_conditions
		assert_equal ['(groups.is_visible = 1)'], Group.search_conditions({:only_visible=>true})
		assert_equal nil, Group.search_conditions({:u=>users(:admin)})
		assert_equal ['(groups.is_visible = 1)'],
			Group.search_conditions({:only_visible=>true, :u=>users(:admin)})
		assert_equal ['(groups.name LIKE ? OR groups.subpath LIKE ? OR groups.description LIKE ?)',
				'%keyword%', '%keyword%', '%keyword%'],
			Group.search_conditions({:u=>users(:admin), :key=>'keyword'})
		assert_equal ['(groups.is_visible = 1) AND (groups.name LIKE ? OR groups.subpath LIKE ? OR groups.description LIKE ?)',
				'%keyword%', '%keyword%', '%keyword%'],
			Group.search_conditions({:only_visible=>true, :key=>'keyword'})
	end
	
	def test_group_find_by_subpath_as_param_id
		assert_equal groups(:one), Group.find('one')
	end
	def test_group_find_by_subpath_as_param_id_with_string_conditions
		assert_equal groups(:one), Group.find('one', 'true')
		assert_raise ActiveRecord::RecordNotFound do
			Group.find('one', :conditions=>'false')
		end
	end
	def test_group_find_by_subpath_as_param_id_with_array_of_conditions
		assert_equal groups(:one), Group.find('one',
			:conditions=>['groups.name LIKE ?', 'Group%'])
		assert_raise ActiveRecord::RecordNotFound do
			Group.find('one',  :conditions=>['groups.name = ?', 'false'])
		end
	end
	def test_group_find_by_subpath_as_param_id_with_array_of_conditions_hash_params
		assert_equal groups(:one),
			Group.find('one', :conditions=>['groups.name LIKE :name', {:name=>'Group%'}])
		assert_raise ActiveRecord::RecordNotFound do
			Group.find('one',  :conditions=>['groups.name = :name', {:name=>'false'}])
		end
	end
	def test_group_find_by_subpath_as_param_id_with_invalid_conditions
		assert_raise Exception do
			Group.find('one', :conditions=>:invalid)
		end
	end
		
	def test_group_line_to_email
		assert_equal ['line-to-email@wayground.ca', nil],
			Group.line_to_email('line-to-email@wayground.ca')
	end
	
	
	# INSTANCE METHODS
	
	def test_group_to_param
		assert_equal 'one', groups(:one).to_param
	end
	
	def test_group_user_membership
		assert_equal memberships(:owner),
			groups(:membered_group).user_membership(users(:login))
	end
	def test_group_user_membership_nonmember
		assert_nil groups(:membered_group).user_membership(users(:nonmember))
	end
	
	# user access/non-access
	def test_public_group_user_can_access
		assert groups(:membered_group).user_can_access?(users(:nonmember))
	end
	def test_private_group_member_can_access
		assert groups(:private_group).user_can_access?(users(:regular))
	end
	def test_private_group_nonmember_has_no_access
		assert !(groups(:private_group).user_can_access?(users(:nonmember)))
	end
	def test_private_group_blocked_member_has_no_access
		assert !(groups(:private_group).user_can_access?(users(:another)))
	end
	def test_private_group_expired_member_has_no_access
		assert !(groups(:private_group).user_can_access?(users(:someone)))
	end
	def test_private_group_invited_member_has_no_access
		assert !(groups(:private_group).user_can_access?(users(:plain)))
	end
	
	def test_group_user_can_admin
		assert groups(:membered_group).user_can_admin?(users(:login))
	end
	def test_group_user_can_admin_fail_nonmember
		assert !(groups(:membered_group).user_can_admin?(users(:nonmember)))
	end
	def test_group_user_can_admin_fail_nonadmin
		assert !(groups(:membered_group).user_can_admin?(users(:regular)))
	end
	def test_group_user_can_admin_fail_no_user
		assert !(groups(:membered_group).user_can_admin?(nil))
	end
	
	def test_group_user_can_join
		assert groups(:membered_group).user_can_join?(users(:nonmember))
	end
	def test_group_user_can_join_fail_invite_only
		assert !(groups(:private_group).user_can_join?(users(:nonmember)))
	end
	def test_group_user_can_join_fail_existing_member
		assert !(groups(:membered_group).user_can_join?(users(:regular)))
	end
	
	def test_has_access_to_by_owner
		assert groups(:private_group).has_access_to?(nil, groups(:private_group).owner)
	end
	def test_has_access_to_by_admin_user
		assert groups(:private_group).has_access_to?(nil, users(:admin))
	end
	def test_has_access_to_by_staff_user
		assert groups(:private_group).has_access_to?(nil, users(:staff))
	end
	def test_has_access_to_admin_by_admin_member
		assert groups(:private_group).has_access_to?(:admin, memberships(:private_admin).user)
	end
	def test_has_access_to_self_join_by_existing_member
		assert !(groups(:private_group).has_access_to?(:self_join,
			memberships(:private_member).user))
	end
	def test_has_access_to_self_join_by_blocked
		assert !(groups(:private_group).has_access_to?(:self_join,
			memberships(:blockee).user))
	end
	def test_has_access_to_self_join_by_invitee
		assert groups(:private_group).has_access_to?(:self_join,
			memberships(:invitee).user)
	end
	def test_has_access_to_self_join_by_uninvited
		assert !(groups(:private_group).has_access_to?(:self_join, users(:nonmember)))
	end
	def test_has_access_to_self_join_open_group_by_nonmember
		assert groups(:public_group).has_access_to?(:self_join, users(:nonmember))
	end
	def test_has_access_to_member_list_open_group_by_nonmember
		assert groups(:public_group).has_access_to?(:member_list, users(:nonmember))
	end
	def test_has_access_to_member_list_private_group_by_nonmember
		assert !(groups(:private_group).has_access_to?(:member_list, users(:nonmember)))
	end
	def test_has_access_to_member_list_private_group_by_member
		assert !(groups(:private_group).has_access_to?(:member_list,
			memberships(:private_member).user))
	end
	def test_has_access_to_member_list_private_group_by_member_with_member_manage
		# set the can_manage_members for a member with no other special permissions
		memberships(:private_member).update_attribute(:can_manage_members, true)
		assert groups(:private_group).has_access_to?(:member_list,
			memberships(:private_member).user)
		# reset the flag
		memberships(:private_member).update_attribute(:can_manage_members, false)
	end
	def test_has_access_to_member_list_private_group_by_admin_member
		assert groups(:private_group).has_access_to?(:member_list,
			memberships(:private_admin).user)
	end
	
	def test_group_email_addresses
		# TODO: implement this test and the email_addresses method
		assert_equal([], groups(:one).email_addresses)
	end
	
	def test_group_email_addresses_with_details
		# TODO: implement this test and the email_addresses_with_details method
		assert_equal({}, groups(:one).email_addresses_with_details)
	end
	
	def test_group_bulk_add
		old_count = groups(:one).memberships.count
		# FIXME: not sure why assert_difference isn’t working here :-(
		#assert_difference(groups(:one).memberships, :count, 3) do
			bulk_result = groups(:one).bulk_add(
				"bulk-test@wayground.ca\n" +
				"\n" + "bad line\n" + "\n" + "bad-address@wayground\n" +
				"<login_test@wayground.ca>\n" + # memberships(:one_active_membership)
				"regular-user@wayground.ca\n" + # memberships(:one_inactive_membership)
				"nonmember-user@wayground.ca\n" + # users(:nonmember)
				"Another Bulk <anotherbulk-test@wayground.ca>\n",
				users(:login))
			assert_equal 5, bulk_result[:memberships].size	
			assert_equal 4, bulk_result[:added]
			assert_equal 2, bulk_result[:blanks]
			assert_equal [[3, 'bad line'], [5, 'bad-address@wayground']],
				bulk_result[:bad_lines]
		#end
		assert_equal old_count + 3, groups(:one).memberships.count
	end
	
	def test_group_bulk_remove
		# load up the group with members to remove
		bulk_result = groups(:one).bulk_add(
			"bulk-test@wayground.ca\n" +
			"nonmember-user@wayground.ca\n" + # users(:nonmember)
			"Another Bulk <anotherbulk-test@wayground.ca>\n")
		old_count = groups(:one).memberships.count
		# FIXME: not sure why assert_difference isn’t working here :-(
		#assert_difference(groups(:one).memberships, :count, 3) do
			bulk_result = groups(:one).bulk_remove(
				"bulk-test@wayground.ca\n" +
				"\n" + "bad line\n" + "\n" + "bad-address@wayground\n" +
				"non-existent@wayground.ca\n" +
				"<login_test@wayground.ca>\n" + # memberships(:one_active_membership)
				"regular-user@wayground.ca\n" + # memberships(:one_inactive_membership)
				"nonmember-user@wayground.ca\n" + # users(:nonmember)
				"Another Bulk <anotherbulk-test@wayground.ca>\n")
			assert_equal 4, bulk_result[:users_removed].size	
			assert_equal ['non-existent@wayground.ca', 'regular-user@wayground.ca'],
				bulk_result[:missing]
			assert_equal 2, bulk_result[:blanks]
			assert_equal [[3, 'bad line'], [5, 'bad-address@wayground']],
				bulk_result[:bad_lines]
		#end
		assert_equal old_count - 4, groups(:one).memberships.count
	end
	
	def test_group_css_class
		assert_equal 'group', groups(:one).css_class
	end
	def test_group_css_class_with_prefix
		assert_equal 'test-group', groups(:one).css_class('test-')
	end
	
	def test_group_link
		assert_equal groups(:one), groups(:one).link
	end
	
	def test_group_title
		assert_equal 'Group One', groups(:one).title
	end
	def test_group_title_assignment
		assert_raise Exception do
			groups(:one).title = 'This Should Fail'
		end
	end
	
	def test_group_title_prefix
		assert_nil groups(:one).title_prefix
	end
	
end
