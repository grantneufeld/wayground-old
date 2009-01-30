require 'test_helper'

class SiteTest < ActiveSupport::TestCase
	fixtures :sites, :pages, :paths
	
	test 'associations' do
		assert check_associations
	end
	
	test "select_list" do
		site_list = Site.select_list
		assert_equal 4, site_list.size
		assert_equal ['Wayground',''], site_list[0]
		assert site_list.include?([sites(:one).title, sites(:one).id])
	end
end
