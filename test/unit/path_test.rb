require 'test_helper'

class PathTest < ActiveSupport::TestCase
	fixtures :pages, :users, :paths
	
	def test_associations
		assert check_associations
		#assert_equal users(:admin), pages(:front_page).user
	end
	
	
	# CLASS METHODS
	
	def test_find_home_path
		path = Path.find_home
		assert_equal paths(:one), path
	end
	
	def test_find_by_key
		p = Path.find_by_key('two')
		assert_equal 2, p.length
		assert_equal paths(:two), p[0]
	end
	
	# INSTANCE METHODS
	
	# TODO: test path.redirect support
	
end
