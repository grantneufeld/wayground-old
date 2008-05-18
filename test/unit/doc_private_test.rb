require File.dirname(__FILE__) + '/../test_helper'

class DocPrivateTest < ActiveSupport::TestCase
	# The full set of tests for the DocPrivate class are handled in DocumentTest
	
	def test_associations
		assert check_associations(DocPrivate)
	end
end
