require 'test_helper'

class GroupTest < ActiveSupport::TestCase
	fixtures :groups, :users, :locations
	
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
	
	def test_group_search_conditions
		assert_equal ['(groups.is_visible = 1)'], Group.search_conditions
		assert_equal ['(groups.is_visible = 1)'], Group.search_conditions(true)
		assert_equal [''], Group.search_conditions(false, users(:admin))
		assert_equal ['(groups.is_visible = 1)'],
			Group.search_conditions(true, users(:admin))
		assert_equal ['(groups.name LIKE ? OR groups.subpath LIKE ? OR groups.description LIKE ?)',
				'%keyword%', '%keyword%', '%keyword%'],
			Group.search_conditions(false, users(:admin), 'keyword')
		assert_equal ['(groups.is_visible = 1) AND (groups.name LIKE ? OR groups.subpath LIKE ? OR groups.description LIKE ?)',
				'%keyword%', '%keyword%', '%keyword%'],
			Group.search_conditions(true, nil, 'keyword')
	end
	
	
	# INSTANCE METHODS
	
	def test_group_display_name
		assert_equal 'Group One', groups(:one).display_name
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
	
end
