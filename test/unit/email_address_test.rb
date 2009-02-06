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
	
	
	# INSTANCE METHODS
	
	test "before save makes activation code" do
		e = EmailAddress.new(:email=>'before-save+test@wayground.ca')
		e.user = users(:login)
		e.save!
		assert !(e.activation_code.blank?)
	end
	test "before save does not make activation code when no user" do
		e = EmailAddress.new(:email=>'before-save-no-code+test@wayground.ca')
		e.save!
		assert e.activation_code.blank?
	end
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
		u.email_addresses << e
		u.save!
		u.email_addresses << e2
		u.save!
		assert_equal 1, e.position
		assert_equal 2, e2.position
	end
	
	test "make activation code" do
		e = EmailAddress.new
		e.make_activation_code
		assert !(e.activation_code.blank?)
	end
	
	test "activate" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		e.activation_code = 'test'
		e.activate!('test')
		assert_nil e.activation_code
		assert e.activated_at
	end
	test "activate fails on wrong code" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		e.activation_code = 'test'
		assert_raise Wayground::ActivationCodeMismatch do
			e.activate!('wrong')
		end
	end
	test "activate fails when has no code set" do
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		assert_raise Wayground::CannotBeActivated do
			e.activate!(nil)
		end
	end
	
	test "assign to user moves email and activation" do
		email = 'move-email+test@wayground.ca'
		u = User.new(:fullname=>'Move Email')
		e = EmailAddress.new(:email=>email)
		e.assign_to_user!(u)
		assert_equal email, u.email
		assert u.activation_code
		assert_nil u.activated_at
		u.destroy
	end
	test "assign to user saves user" do
		u = User.new(:fullname=>'Save User')
		e = EmailAddress.new(:email=>'save-user+test@wayground.ca')
		assert_difference(User, :count, 1) do
			e.assign_to_user!(u)
		end
		u.destroy
	end
	test "assign to user destroys emailaddress if moved" do
		u = User.new(:fullname=>'Destroy EmailAddress')
		e = EmailAddress.new(:email=>'destroy-emailaddress+test@wayground.ca')
		e.save!
		assert_difference(EmailAddress, :count, -1) do
			e.assign_to_user!(u)
		end
		u.destroy
	end
	test "assign to user saves emailaddress if user already has email" do
		u = User.new(:fullname=>'Save EmailAddress', :email=>'user+test@wayground.ca')
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
	
	test "move memberships to user assigns user" do
		u = User.new(:fullname=>'Move Memberships')
		e = EmailAddress.new(:email=>'move+test@wayground.ca')
		e.user = u
		m = Membership.new()
		m.group = groups(:one)
	#	m.email_address = e
		e.memberships << m
		e.move_memberships_to_user!
		assert_equal u, m.user
	end
	test "move memberships to user removes email address from membership" do
		u = User.new(:fullname=>'Move Memberships')
		e = EmailAddress.new(:email=>'move+test@wayground.ca')
		e.user = u
		m = Membership.new()
		m.group = groups(:one)
	#	m.email_address = e
		e.memberships << m
		e.move_memberships_to_user!
		assert_nil m.email_address
	end
	test "move memberships to user saves membership" do
		u = User.new(:fullname=>'Move Memberships')
		e = EmailAddress.new(:email=>'move+test@wayground.ca')
		e.user = u
		m = Membership.new()
		m.group = groups(:one)
	#	m.email_address = e
		e.memberships << m
		e.move_memberships_to_user!
		assert m.id > 0
	end
	test "move memberships to user does not override existing user" do
		u = User.new(:fullname=>'Move Memberships')
		u2 = User.new(:fullname=>'Prior User')
		e = EmailAddress.new(:email=>'move+test@wayground.ca')
		e.user = u
		m = Membership.new()
		m.user = u2
		m.group = groups(:one)
	#	m.email_address = e
		e.memberships << m
		e.move_memberships_to_user!
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
	
end
