require 'test_helper'

class EmailAddressTest < ActiveSupport::TestCase
	fixtures :email_addresses, :users, :groups #, :memberships
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	test "validates email" do
		e = EmailAddress.new(:email=>'validation+test@wayground.ca')
		assert_valid e
	end
	test "validation fails on missing email" do
		e = EmailAddress.new()
		assert_validation_fails_for(e, ['email'])
	end
	test "validation fails on bad email format" do
		e = EmailAddress.new(:email=>'invalid')
		assert_validation_fails_for(e, ['email'])
	end
	test "validation fails on duplicate email address" do
		e = EmailAddress.new(:email=>email_addresses(:one).email)
		e.user = email_addresses(:one).user
		assert_validation_fails_for(e, ['email'])
	end
	test "validation fails on invalid domain for email" do
		e = EmailAddress.new(:email=>'test@invalid.domain')
		assert_validation_fails_for(e, ['email'])
	end
	
	
	# CLASS METHODS
	
	test "activate" do
		email = 'activate+test@wayground.ca'
		e = EmailAddress.create(:email=>email)
		EmailAddress.activate!(users(:login), e.activation_code, e.encrypt_code)
		e = EmailAddress.find(e.id)
		assert_nil e.activation_code
		assert !(e.activated_at.blank?)
		assert_equal users(:login), e.user
	end
	test "activate fails on wrong code" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		e.save!
		assert_raise Wayground::ActivationCodeMismatch do
			EmailAddress.activate!(users(:login), 'wrong', e.encrypt_code)
		end
	end
	test "activate fails when has no code set" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		e.save!
		assert_raise Wayground::CannotBeActivated do
			EmailAddress.activate!(users(:login), nil, e.encrypt_code)
		end
	end
	test "activate fails when has no user set" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		e.save!
		assert_raise Wayground::CannotBeActivated do
			EmailAddress.activate!(nil, e.activation_code, e.encrypt_code)
		end
	end
	test "activate fails when has no encrypt code set" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		e.save!
		assert_raise Wayground::CannotBeActivated do
			EmailAddress.activate!(users(:login), e.activation_code, nil)
		end
	end
	test "activate fails when encrypt code does not match" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		e.save!
		assert_raise Wayground::ActivationCodeMismatch do
			EmailAddress.activate!(users(:login), e.activation_code, 'invalid')
		end
	end
	test "activate removes matching email from other users" do
		email = 'activate+test@wayground.ca'
		e = EmailAddress.create(:email=>email)
		u = User.create(:fullname=>'Has Duplicate', :email=>email)
		EmailAddress.activate!(users(:login), e.activation_code, e.encrypt_code)
		u.reload
		assert_nil u.email
	end
	
	
	# INSTANCE METHODS
	
	test "before save makes activation code" do
		e = EmailAddress.new(:email=>'before-save+test@wayground.ca')
		e.user = users(:login)
		e.save!
		assert !(e.activation_code.blank?)
	end
	#test "before save does not make activation code when no user" do
	#	e = EmailAddress.new(:email=>'before-save-no-code+test@wayground.ca')
	#	e.save!
	#	assert e.activation_code.blank?
	#end
	test "before save defaults to zero position when no user" do
		e = EmailAddress.new(:email=>'no-user+test@wayground.ca')
		e.save!
		assert_equal 0, e.position
	end
	test "before save assigns position" do
		e = EmailAddress.new(:email=>'save-position+test@wayground.ca')
		u = User.new(:fullname=>'Email User', :email=>'user+test@wayground.ca')
		u.email_addresses << e
		u.save!
		assert_equal 1, e.position
	end
	test "before save assigns position when previously saved with no user" do
		e = EmailAddress.new(:email=>'previously-saved+test@wayground.ca')
		e.save!
		u = User.new(:fullname=>'Email User', :email=>'user+test@wayground.ca')
		u.email_addresses << e
		u.save!
		assert_equal 1, e.position
	end
	test "before save assigns position when user has multiple addresses" do
		e = EmailAddress.new(:email=>'multiple-address1+test@wayground.ca')
		e2 = EmailAddress.new(:email=>'multiple-address2+test@wayground.ca')
		u = User.new(:fullname=>'Email User', :email=>'user+test@wayground.ca')
		u.save!
		u.email_addresses << e
		u.email_addresses << e2
		e.reload
		e2.reload
		assert_equal 2, e.position
		assert_equal 3, e2.position
	end
	
	test "make activation code" do
		e = EmailAddress.new
		e.make_activation_code
		assert_kind_of String, e.activation_code
		assert !(e.activation_code.blank?)
	end
	
	test "user activated" do
		email = 'activate+test@wayground.ca'
		e = EmailAddress.create(:email=>email)
		EmailAddress.activate!(users(:login), e.activation_code, e.encrypt_code)
		e = EmailAddress.find(e.id)
		assert e.activated?
	end
	test "user not activated" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		assert !(e.activated?)
	end
	
	test "assign to user saves user" do
		u = User.new(:fullname=>'Save User')
		e = EmailAddress.new(:email=>'save-user+test@wayground.ca')
		assert_difference(User, :count, 1) do
			e.assign_to_user!(u)
		end
		u.destroy
	end
	test "assign to user saves emailaddress" do
		u = User.new(:fullname=>'Save EmailAddress', :email=>'user+test@wayground.ca')
		u.save!
		e = EmailAddress.new(:email=>'save-emailaddress+test@wayground.ca')
		assert_difference(EmailAddress, :count, 1) do
			e.assign_to_user!(u)
		end
		u.destroy
	end
	test "assign to user returns user" do
		u = User.new(:fullname=>'Return User')
		e = EmailAddress.new(:email=>'return-user+test@wayground.ca')
		assert_equal u, e.assign_to_user!(u)
		u.destroy
	end
	
	test "assign memberships to user assigns user" do
		u = User.new(:fullname=>'Move Memberships')
		e = EmailAddress.new(:email=>'move+test@wayground.ca')
		e.user = u
		e.save!
		m = Membership.new()
		m.group = groups(:one)
	#	m.email_address = e
		e.memberships << m
		e.assign_memberships_to_user!
		m = Membership.find(m.id)
		assert_equal u, m.user
	end
	test "assign memberships to user saves membership" do
		u = User.new(:fullname=>'Move Memberships')
		e = EmailAddress.new(:email=>'move+test@wayground.ca')
		e.user = u
		e.save!
		m = Membership.new()
		m.group = groups(:one)
	#	m.email_address = e
		e.memberships << m
		e.assign_memberships_to_user!
		assert m.id > 0
	end
	test "assign memberships to user does not override existing user" do
		u = User.new(:fullname=>'Move Memberships')
		u.save!
		u2 = User.new(:fullname=>'Prior User')
		u2.save!
		e = EmailAddress.new(:email=>'move+test@wayground.ca')
		e.user = u
		e.save!
		m = Membership.new()
		m.user = u2
		groups(:one).memberships << m
	#	m.email_address = e
		e.memberships << m
		e.assign_memberships_to_user!
		assert_equal u2, m.user
	end
	
	test "is confirmed" do
		e = EmailAddress.new(:email=>'confirm+test@wayground.ca')
		e.user = users(:login)
		e.activated_at = Time.now
		assert e.is_confirmed?
	end
	test "is confirmed fails with no user" do
		e = EmailAddress.new(:email=>'nouser+test@wayground.ca')
		e.activated_at = Time.now
		assert !(e.is_confirmed?)
	end
	test "is confirmed fails when not activated" do
		e = EmailAddress.new(:email=>'notactivated+test@wayground.ca')
		e.user = users(:login)
		assert !(e.is_confirmed?)
	end
	test "is confirmed fails when no user and not activated" do
		e = EmailAddress.new(:email=>'confirm-nouseroractivate+test@wayground.ca')
		assert !(e.is_confirmed?)
	end
	
	test "to string when blocked" do
		email = 'test@wayground.ca'
		e = EmailAddress.new(:email=>email)
		e.is_blocked = true
		assert_nil e.to_s
	end
	test "to string when no name" do
		email = 'test@wayground.ca'
		e = EmailAddress.new(:email=>email)
		assert_equal email, e.to_s
	end
	test "to string when just basic name" do
		email = 'test@wayground.ca'
		name = 'Test Name'
		e = EmailAddress.new(:email=>email, :name=>name)
		assert_equal "#{name} <#{email}>", e.to_s
	end
	test "to string when name with complicated chars" do
		email = 'test@wayground.ca'
		name = 'Test-This A. Name'
		e = EmailAddress.new(:email=>email, :name=>name)
		assert_equal "\"#{name}\" <#{email}>", e.to_s
	end
end
