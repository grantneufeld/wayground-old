require 'test_helper'

class WeblinkTest < ActiveSupport::TestCase
	fixtures :weblinks, :users
	
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
	
	
	# CLASS METHODS
	
	def test_weblink_default_include
		assert_nil Weblink.default_include
	end
	
	def test_weblink_default_order
		assert_equal 'weblinks.category, weblinks.position, weblinks.title',
			Weblink.default_order
	end
	def test_weblink_default_order_recent
		assert_equal 'weblinks.updated_at DESC, weblinks.category, weblinks.position, weblinks.title',
			Weblink.default_order({:recent=>true})
	end
	
	def test_weblink_search_conditions
		assert_nil Weblink.search_conditions
	end
	def test_weblink_search_conditions_custom
		assert_equal ['a AND b',1,2], Weblink.search_conditions({}, ['a','b'], [1,2])
	end
	def test_weblink_search_conditions_key
		assert_equal ['(weblinks.title LIKE ? OR weblinks.url LIKE ?)',
			'%keyword%', '%keyword%'],
			Weblink.search_conditions({:key=>'keyword'})
	end
	def test_weblink_search_conditions_all
		assert_equal ['a AND b AND (weblinks.title LIKE ? OR weblinks.url LIKE ?)',
			1, 2, '%keyword%', '%keyword%'],
			Weblink.search_conditions({:key=>'keyword'}, ['a','b'], [1,2])
	end
	
	
	# INSTANCE METHODS
	
	def test_weblink_set_confirmation
		
	end
	
	def test_weblink_set_title
		
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
	
	def test_weblink_set_site
		
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
	
	def test_weblink_is_confirmed
		
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
	
	def test_weblink_css_class
		assert_equal 'url', weblinks(:one).css_class
	end
	def test_weblink_css_class_with_prefix
		assert_equal 'test-url', weblinks(:one).css_class('test-')
	end
	
	def test_weblink_link
		assert_equal weblinks(:one).url, weblinks(:one).link
	end
	
	def test_weblink_title_prefix
		assert_nil weblinks(:one).title_prefix
	end
	
end
