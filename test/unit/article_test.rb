require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < ActiveSupport::TestCase
	fixtures :pages, :users, :paths
	
	def test_associations
		assert check_associations
	end
	
	# CLASS METHODS
	
	def test_article_default_order
		assert_equal 'pages.created_at DESC, pages.title', Article.default_order
	end
	def test_article_default_order_recent
		assert_equal 'pages.updated_at DESC, pages.created_at DESC, pages.title',
			Article.default_order({:recent=>true})
	end
	
	def test_article_search_conditions
		assert_equal nil, Article.search_conditions
	end
	def test_article_search_conditions_custom
		assert_equal ['a AND b',1,2], Article.search_conditions({}, ['a','b'], [1,2])
	end
	def test_article_search_conditions_key
		assert_equal ['(pages.title like ? OR pages.description like ? OR pages.content like ? OR pages.keywords like ? OR pages.author like ? OR pages.issue like ?)',
			'%keyword%', '%keyword%', '%keyword%', '%keyword%', '%keyword%', '%keyword%'],
			Article.search_conditions({:key=>'keyword'})
	end
	def test_article_search_conditions_author
		assert_equal ['pages.author like ?', '%author%'],
			Article.search_conditions({:author=>'author'})
	end
	def test_article_search_conditions_issue
		assert_equal ['pages.issue like ?', '%issue%'],
			Article.search_conditions({:issue=>'issue'})
	end
	def test_article_search_conditions_all
		assert_equal ['(pages.title like ? OR pages.description like ? OR pages.content like ? OR pages.keywords like ? OR pages.author like ? OR pages.issue like ?) AND pages.author like ? AND pages.issue like ?',
			'%keyword%', '%keyword%', '%keyword%', '%keyword%', '%keyword%', '%keyword%',
			'%author%', '%issue%'],
			Article.search_conditions({:key=>'keyword', :author=>'author', :issue=>'issue'})
	end
	
	# INSTANCE METHODS
	

end
