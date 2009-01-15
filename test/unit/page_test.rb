require File.dirname(__FILE__) + '/../test_helper'

class PageTest < ActiveSupport::TestCase
	fixtures :pages, :users, :paths
	
	def test_associations
		assert check_associations
		#assert_equal users(:admin), pages(:front_page).user
	end
	
	
	# VALIDATIONS
	
	def test_page_required_fields_validation
		p = Page.new
		assert_validation_fails_for(p, ['subpath', 'title'])
	end
	
	def test_page_subpath_validation
		p = Page.new :subpath=>'subpath', :title=>'Test'
		assert_valid p
	end
	def test_page_subpath_validation_with_extension
		p = Page.new :subpath=>'subpath.html', :title=>'Test'
		assert_valid p
	end
	def test_page_subpath_validation_missing
		p = Page.new :title=>'Test'
		assert_validation_fails_for(p, ['subpath'])
	end
	def test_page_subpath_validation_invalid
		p = Page.new :subpath=>'• This is invalid!/whatever..$', :title=>'Test'
		assert_validation_fails_for(p, ['subpath'])
	end
	def test_page_subpath_validation_duplicate
		p = Page.new :subpath=>'page2', :title=>'Test'
		assert_validation_fails_for(p, ['subpath'])
	end
	
	def test_page_title_validation_missing
		p = Page.new :subpath=>'subpath'
		assert_validation_fails_for(p, ['title'])
	end
	
	def test_page_content_type_validation
		i = 0
		%w(text/plain text/html text/wayground).each do |content_type|
			i += 1
			p = Page.new(:subpath=>"subpath#{i}", :title=>'Test',
				:content_type=>content_type)
			assert_valid p
		end
	end
	def test_page_content_type_validation_missing_for_content
		p = Page.new :subpath=>'subpath', :title=>'Test', :content=>'Test'
		assert_validation_fails_for(p, ['content_type'])
	end
	def test_page_content_type_validation_invalid
		p = Page.new :subpath=>'subpath', :title=>'Test',
			:content_type=>'application/pdf'
		assert_validation_fails_for(p, ['content_type'])
	end
	
	
	# CLASS METHODS
	
	def test_find_home
		page = Page.find_home
		assert_equal pages(:one), page
	end
	
	def test_find_by_key
		p = Page.find_by_key('keyword')
		assert_equal 2, p.length
		assert_equal pages(:three), p[0]
	end
	
	def test_page_search_conditions
		assert_equal [''], Page.search_conditions
	end
	def test_page_search_conditions_custom
		assert_equal ['a AND b',1,2], Page.search_conditions({}, ['a','b'], [1,2])
	end
	def test_page_search_conditions_keyword
		assert_equal([
				'(pages.title LIKE ? OR pages.description LIKE ? OR pages.content LIKE ? OR pages.keywords LIKE ?)',
				'%keyword%', '%keyword%', '%keyword%', '%keyword%'],
			Page.search_conditions({:key=>'keyword'}))
	end
	def test_page_search_conditions_keyword_and_custom
		assert_equal([
			'a AND b AND (pages.title LIKE ? OR pages.description LIKE ? OR pages.content LIKE ? OR pages.keywords LIKE ?)',
			1, 2, '%keyword%', '%keyword%', '%keyword%', '%keyword%'],
			Page.search_conditions({:key=>'keyword'}, ['a','b'], [1,2]))
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
	def test_new_invalid_subpath_format
		page = Page.new(:subpath=>'An Invalid Subpath!', :title=>'Invalid')
		assert page
		assert !(page.save)
	end
	def test_new_invalid_subpath_restricted
		page = Page.new(:subpath=>'documents', :title=>'Invalid')
		assert page
		assert !(page.save)
	end
	def test_new_invalid_content_type
		page = Page.new(:subpath=>'invalid_content_type', :title=>'Invalid',
			:content_type=>'invalid/mimetype')
		assert page
		assert !(page.save)
	end
	def test_new_invalid_sitepath_duplicate
		page = Page.new(:subpath=>pages(:two).subpath, :title=>'Invalid')
		assert page
		assert !(page.save)
	end
	
	def test_delete
		pages(:delete_this).destroy
		assert pages(:delete_this).frozen?
	end
	
	def test_parent_chain_no_parents
		assert_equal [], pages(:one).parent_chain
	end
	def test_parent_chain_one_parent
		assert_equal [pages(:one)], pages(:two).parent_chain
	end
	def test_parent_chain_two_parents
		assert_equal [pages(:one), pages(:two)], pages(:three).parent_chain
	end
	
	def test_page_is_home
		assert pages(:one).is_home?
	end
	def test_page_is_home_not
		assert !(pages(:two).is_home?)
	end
	
	def test_page_css_class
		assert_equal 'root', pages(:one).css_class
	end
	def test_page_css_class_prefix
		assert_equal 'dir-page', pages(:two).css_class('dir-')
	end
end
