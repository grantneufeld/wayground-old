require 'test_helper'

class WeblinkTest < ActiveSupport::TestCase
	fixtures :users
	
	def test_weblink_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	def test_weblink_valid_url
		l = Weblink.new({:url=>'http://wayground.ca/'})
		l.user = users(:login)
		assert l.valid?
	end
	def test_weblink_invalid_url
		l = Weblink.new({:url=>'wayground.ca'})
		l.user = users(:login)
		assert !(l.valid?)
		l = Weblink.new({:url=>'http:// wayground.ca/'})
		l.user = users(:login)
		assert !(l.valid?)
	end
	
	# IS_CONFIRMED
	def test_weblink_admin_confirms
		l = Weblink.new({:url=>'http://wayground.ca/'})
		l.user = users(:admin)
		assert l.valid?
		assert l.is_confirmed?
	end
	def test_weblink_staff_confirms
		l = Weblink.new({:url=>'http://wayground.ca/'})
		l.user = users(:staff)
		assert l.valid?
		assert l.is_confirmed?
	end
	def test_weblink_plain_user_does_not_confirm
		l = Weblink.new({:url=>'http://wayground.ca/'})
		l.user = users(:plain)
		assert l.valid?
		assert !(l.is_confirmed)
	end
	
	# AUTO-SET TITLE
	def test_weblink_title_autoset
		l = Weblink.new({:url=>'http://wayground.ca/'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'wayground.ca', l.title
	end
	def test_weblink_title_autoset_long
		l = Weblink.new({:url=>'http://wayground.ca/test'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'wayground.ca…', l.title
	end
	def test_weblink_title_autoset_short
		l = Weblink.new({:url=>'http://wayground.ca'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'wayground.ca', l.title
	end
	def test_weblink_title_no_autoset
		l = Weblink.new({:url=>'http://wayground.ca/', :title=>'Wayground'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'Wayground', l.title
	end
	
	# AUTO-SET SITE
	def test_weblink_site_autoset
		l = Weblink.new({:url=>'http://wayground.ca/'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'wayground', l.site
	end
	def test_weblink_site_autoset_short
		l = Weblink.new({:url=>'http://wayground.ca'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'wayground', l.site
	end
	def test_weblink_site_no_autoset
		l = Weblink.new({:url=>'http://wayground.ca/', :site=>'override'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'override', l.site
	end
	def test_weblink_site_autoset_long
		l = Weblink.new({:url=>'http://www.long.wayground.ca/test'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'wayground', l.site
	end
	def test_weblink_site_autoset_blogspot
		l = Weblink.new({:url=>'http://wayground.blogspot.com/'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'blogger', l.site
	end
	def test_weblink_site_autoset_magnolia
		l = Weblink.new({:url=>'http://ma.gnolia.com/people/test'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'magnolia', l.site
	end
	def test_weblink_site_autoset_delicious
		l = Weblink.new({:url=>'http://del.icio.us/test'})
		l.user = users(:login)
		assert l.valid?
		assert_equal 'delicious', l.site
	end
	
end
