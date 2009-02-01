require 'test_helper'

class GroupTest < ActiveSupport::TestCase
	fixtures :groups, :users, :memberships, :locations
	
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
	
	def test_group_email_addresses
		# TODO: implement this test and the email_addresses method
		assert_equal([], groups(:one).email_addresses)
	end
	
	def test_group_email_addresses_with_details
		# TODO: implement this test and the email_addresses_with_details method
		assert_equal({}, groups(:one).email_addresses_with_details)
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
	
	def test_group_title_prefix
		assert_nil groups(:one).title_prefix
	end
	
end
