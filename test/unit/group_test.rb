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
	
	
	# INSTANCE METHODS
	
end
