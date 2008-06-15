require File.dirname(__FILE__) + '/../test_helper'

class PageTest < ActiveSupport::TestCase
	fixtures :pages, :users, :paths
	
	def test_associations
		assert check_associations
		#assert_equal users(:admin), pages(:front_page).user
	end
	
	
	# CLASS METHODS
	
	def test_find_home
		page = Page.find_home
		assert_equal pages(:one), page
	end
	
	
	# INSTANCE METHODS
	
	def test_new
		page = Page.new(:subpath=>'new_page', :title=>'New Page',
			:description=>'This is a new page.',
			:content=>'The content for a new page.', :content_type=>'text/plain',
			:keywords=>'new, create')
		assert page
		page.user = users(:login)
		page.editor = users(:login)
		page.parent = pages(:one)
		assert page.save
		assert_equal '/new_page', page.sitepath
	end
	def test_new_minimum_values
		page = Page.new(:subpath=>'minimal', :title=>'New Minimal Page')
		assert page
		assert page.save
		assert_equal '/minimal', page.sitepath
	end
	def test_new_no_values
		page = Page.new()
		assert page
		assert !(page.save)
	end
	def test_new_invalid_values
		# invalid subpath format
		page = Page.new(:subpath=>'An Invalid Subpath!', :title=>'Invalid')
		assert page
		assert !(page.save)
		# invalid content_type format
		page = Page.new(:subpath=>'invalid_content_type', :title=>'Invalid',
			:content_type=>'invalid/mimetype')
		assert page
		assert !(page.save)
		# non-unique sitepath
		page = Page.new(:subpath=>pages(:two).subpath, :title=>'Invalid')
		assert page
		assert !(page.save)
	end
	
	def test_delete
		pages(:delete_this).destroy
		assert pages(:delete_this).frozen?
	end
	
	def test_parent_chain
		assert_equal [], pages(:one).parent_chain
		assert_equal [pages(:one)], pages(:two).parent_chain
		assert_equal [pages(:one), pages(:two)], pages(:three).parent_chain
	end
end
