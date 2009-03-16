require 'test_helper'

class RecipientTest < ActiveSupport::TestCase
	fixtures :email_messages, :email_addresses, :users, :groups, :recipients, :attachments
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	test "minimum attributes to pass validation" do
		r = Recipient.new()
		r.email_message = email_messages(:one)
		r.email_address = email_addresses(:another)
		assert_valid r
	end
	test "validation fails without email_message" do
		r = Recipient.new()
		r.email_address = email_addresses(:another)
		assert_validation_fails_for(r, ['email_message'])
	end
	test "validation fails without email address" do
		r = Recipient.new()
		r.email_message = email_messages(:one)
		assert_validation_fails_for(r, ['email_address'])
	end
	test "validation fails with duplicate email address" do
		r0 = Recipient.new()
		r0.email_message = email_messages(:one)
		r0.email_address = email_addresses(:another)
		r0.save!
		r = Recipient.new()
		r.email_message = email_messages(:one)
		r.email_address = email_addresses(:another)
		assert_validation_fails_for(r, ['email_address_id'])
	end
	
	
	# INSTANCE METHODS
	
	test "to string when no name" do
		email = 'test@wayground.ca'
		e = EmailAddress.new(:email=>email)
		r = Recipient.new()
		r.email_address = e
		assert_equal email, r.to_s
	end
	test "to string when just basic name" do
		email = 'test@wayground.ca'
		name = 'Test Name'
		e = EmailAddress.new(:email=>email, :name=>name)
		r = Recipient.new()
		r.email_address = e
		assert_equal "#{name} <#{email}>", r.to_s
	end
	test "to string when name with complicated chars" do
		email = 'test@wayground.ca'
		name = 'Test-This A. Name'
		e = EmailAddress.new(:email=>email, :name=>name)
		r = Recipient.new()
		r.email_address = e
		assert_equal "\"#{name}\" <#{email}>", r.to_s
	end
		
	test "email" do
		assert_equal email_addresses(:one).email, recipients(:one).email
	end
	
	test "email addresses" do
		assert_equal [email_addresses(:one)], recipients(:one).email_addresses
	end
	
	test "locations" do
		assert_equal [], recipients(:one).locations
	end
	
	test "name" do
		assert_equal email_addresses(:one).name, recipients(:one).name
	end
end
