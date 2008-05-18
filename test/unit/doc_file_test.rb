require File.dirname(__FILE__) + '/../test_helper'

class DocFileTest < ActiveSupport::TestCase
	# The full set of tests for the DocFile class are handled in DocumentTest
	
	def test_associations
		assert check_associations(DocFile)
	end
end
