require 'test_helper'

class MembershipTest < ActiveSupport::TestCase
	fixtures :memberships, :groups, :users, :locations
	
	def test_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	
	# CLASS METHODS
	
	
	# INSTANCE METHODS
	
end
