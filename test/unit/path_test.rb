require 'test_helper'

class PathTest < ActiveSupport::TestCase
	fixtures :items, :users, :paths
	
	def test_associations
		assert check_associations
		#assert_equal users(:admin), items(:front_page).user
	end
	
	
	# CLASS METHODS
	
	def test_find_home_path
		path = Path.find_home
		assert_equal paths(:one), path
	end
	
	
	
	# INSTANCE METHODS
	
	
end
