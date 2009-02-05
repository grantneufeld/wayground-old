require 'test_helper'

class AttachmentTest < ActiveSupport::TestCase
	fixtures :email_messages, :users, :groups, :recipients, :attachments
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
end
