require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < ActiveSupport::TestCase
	fixtures :pages, :users, :paths
	
	def test_associations
		assert check_associations
	end
	
	# CLASS METHODS
	
	# INSTANCE METHODS
	

end
