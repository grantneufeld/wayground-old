require 'test_helper'

class PathTest < ActiveSupport::TestCase
	fixtures :pages, :users, :paths
	
	def test_associations
		assert check_associations
		#assert_equal users(:admin), pages(:front_page).user
	end
	
	
	# VALIDATIONS
	
	def test_path_validation_valid_item
		p = Path.new({:sitepath=>'/test_path_validation_valid_item'})
		i = Page.new({:subpath=>'test_path_validation_valid_item',
			:title=>'test path valid'})
		p.item = i
		assert p.valid?
	end
	def test_path_validation_valid_redirect
		p = Path.new({:sitepath=>'/test_path_validation_valid_redirect',
			:redirect=>'http://wayground.ca/'})
		assert p.valid?
	end
	def test_path_validation_no_item_or_redirect
		p = Path.new({:sitepath=>'/test_path_validation_no_item_or_redirect'})
		assert !(p.valid?)
		assert_equal 1, p.errors.length
		assert !(p.errors[:redirect].blank?)
	end
	def test_path_validation_duplicate_sitepath
		p = Path.new({:sitepath=>'/two',
			:redirect=>'http://wayground.ca/'})
		assert !(p.valid?)
		assert_equal 1, p.errors.length
		assert !(p.errors[:sitepath].blank?)
	end
	def test_path_validation_invalid_sitepath
		p = Path.new({:sitepath=>'invalid sitepath',
			:redirect=>'http://wayground.ca/'})
		assert !(p.valid?)
		assert_equal 1, p.errors.length
		assert !(p.errors[:sitepath].blank?)
	end
	def test_path_validation_invalid_redirect
		p = Path.new({:sitepath=>'/test_path_validation_invalid_redirect',
			:redirect=>'invalid redirect'})
		assert !(p.valid?)
		assert_equal 1, p.errors.length
		assert !(p.errors[:redirect].blank?)
	end
	def test_path_validation_invalid_params
		p = Path.new({:sitepath=>'invalid sitepath',
			:redirect=>'invalid redirect'})
		assert !(p.valid?)
		assert_equal 2, p.errors.length
		assert !(p.errors[:sitepath].blank?)
		assert !(p.errors[:redirect].blank?)
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
	
end
