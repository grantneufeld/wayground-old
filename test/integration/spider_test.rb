require "#{File.dirname(__FILE__)}/../test_helper"

# Crawl links on the site to make sure everything loads okay.
# Uses the spider_test plugin.
class SpiderTest < ActionController::IntegrationTest
	#fixtures :all
	#include Caboose::SpiderIntegrator
	#
	#def test_spider
	#	get '/'
	#	assert_response :success
	#
	#	spider(@response.body, '/', {})
	#end
end
