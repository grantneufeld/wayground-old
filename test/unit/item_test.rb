require File.dirname(__FILE__) + '/../test_helper'

class ItemTest < ActiveSupport::TestCase
	fixtures :items, :users, :paths
	
	def test_associations
		assert check_associations
		#assert_equal users(:admin), items(:front_page).user
	end
	
	
	# CLASS METHODS
	
	def test_find_home
		item = Item.find_home
		assert_equal items(:one), item
	end
	
	
	# INSTANCE METHODS
	
	def test_new
		item = Item.new(:subpath=>'new_item', :title=>'New Item',
			:description=>'This is a new item.',
			:content=>'The content for a new item.', :content_type=>'text/plain',
			:keywords=>'new, create')
		assert item
		item.user = users(:login)
		item.editor = users(:login)
		item.parent = items(:one)
		assert item.save
		assert_equal '/new_item', item.sitepath
	end
	def test_new_minimum_values
		item = Item.new(:subpath=>'minimal', :title=>'New Minimal Item')
		assert item
		assert item.save
		assert_equal '/minimal', item.sitepath
	end
	def test_new_no_values
		item = Item.new()
		assert item
		assert !(item.save)
	end
	def test_new_invalid_values
		# invalid subpath format
		item = Item.new(:subpath=>'An Invalid Subpath!', :title=>'Invalid')
		assert item
		assert !(item.save)
		# invalid content_type format
		item = Item.new(:subpath=>'invalid_content_type', :title=>'Invalid',
			:content_type=>'invalid/mimetype')
		assert item
		assert !(item.save)
		# non-unique sitepath
		item = Item.new(:subpath=>items(:two).subpath, :title=>'Invalid')
		assert item
		assert !(item.save)
	end
	
	def test_delete
		items(:delete_this).destroy
		assert items(:delete_this).frozen?
	end
	
	def test_parent_chain
		assert_equal [], items(:one).parent_chain
		assert_equal [items(:one)], items(:two).parent_chain
		assert_equal [items(:one), items(:two)], items(:three).parent_chain
	end
end
