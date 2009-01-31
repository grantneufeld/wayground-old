require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
	fixtures :users #, :contacts
	
	def test_associations
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	
	# CLASS METHODS
	
	def test_user_default_include
		assert_nil User.default_include
	end
	
	def test_user_default_order
		assert_equal 'users.nickname, users.id', User.default_order
	end
	
	def test_user_search_conditions
		assert_nil User.search_conditions
	end
	def test_user_search_conditions_custom
		assert_equal ['a AND b',1,2], User.search_conditions({}, ['a','b'], [1,2])
	end
	def test_user_search_conditions_with_key
		assert_equal ['users.nickname like ?', '%keyword%'],
			User.search_conditions({:key=>'keyword'})
	end
	def test_user_search_conditions_all
		assert_equal ['a AND b AND users.nickname like ?', 1, 2, '%keyword%'],
			User.search_conditions({:key=>'keyword'}, ['a','b'], [1,2])
	end
	
	def test_password_encrypt
		password = 'password'
		salt = 'salt'
		# Digest::SHA1.hexdigest("--#{salt}--#{password}--")
		expected_result = '81c35bdfd7b6bc8878248ae59671c396aa519764'
		assert_equal expected_result, User.encrypt(password, salt)
	end
	
	def test_login_authenticate
		assert User.authenticate('login_test@wayground.ca', 'password')
	end
	def test_login_authenticate_invalid
		assert_nil User.authenticate('login_test@wayground.ca', 'invalid password')
	end
	
	# INSTANCE METHODS
	
	def test_user_password_changed
		
	end
	
	def test_password_encrypted
		password = 'password'
		assert_equal users(:login).crypted_password,
			users(:login).encrypted(password)
	end
	
	def test_user_email_required
		assert !(users(:minimal).email_required)
	end
	
	def test_user_email_required_assignment
		users(:minimal).email_required = true
		assert users(:minimal).email_required
	end
	
	def test_user_encrypted
		
	end
	
	def test_user_password_matches
		password = 'password'
		assert !(users(:login).password_matches?('fail'))
		assert users(:login).password_matches?(password)
	end
	
	def test_user_encrypt_password
		
	end
	
	def test_make_activation_code
		u = User.new
		u.make_activation_code
		assert(u.activation_code.is_a?(String))
		assert !(u.activation_code.blank?)
	end
	
	def test_activate
		assert users(:activate_this).activate('abc')
		assert users(:activate_this).activation_code.blank?
		assert !(users(:activate_this).activated_at.blank?)
	end
	def test_activate_invalid
		assert !(users(:activate_this_fail).activate(''))
		assert !(users(:activate_this).activation_code.blank?)
		assert users(:activate_this).activated_at.blank?
	end
	
	def test_user_activated
		assert users(:login).activated?
	end
	def test_user_activated_not
		assert !(users(:activate_this).activated?)
	end
	
	def test_user_admin
		assert users(:admin).admin?
	end
	def test_user_admin_not
		assert !(users(:login).admin?)
	end
	
	def test_user_staff
		assert users(:staff).staff?
	end
	def test_user_staff_not
		assert !(users(:login).staff?)
	end
	
	def test_change_password
		old_pass = 'password'
		new_pass = 'new password'
		# try with incorrect old password
		assert !(users(:change_pass).change_password('',new_pass))
		# try with correct old password
		assert users(:change_pass).change_password(old_pass,new_pass)
		# confirm that the new password is set
		assert users(:change_pass).password_matches?(new_pass)
	end
	
	def test_user_profile_path
		
	end
	
	def test_user_remember_token
		
	end
	
	def test_set_remember_me
		assert !(users(:login).remember_token?)
		assert_nil users(:login).remember_token_expires_at
		assert_nil users(:login).remember_token
		users(:login).remember_me
		assert users(:login).remember_token?
		users(:login).forget_me
		assert !(users(:login).remember_token?)
		assert_nil users(:login).remember_token_expires_at
		assert_nil users(:login).remember_token
		# TODO: test remember_token_expires_at values for remember_me, remember_me_for(time) and remember_me_until(time)
	end
	
	def test_user_remember_me_for
		
	end
	
	def test_user_remember_me_until
		
	end
	
	def test_user_forget_me
		
	end
	
	def test_user_css_class
		assert_equal 'user', users(:login).css_class
	end
	def test_user_css_class_with_prefix
		assert_equal 'test-user', users(:login).css_class('test-')
	end
	
	def test_user_description
		assert_nil users(:login).description
	end
	
	def test_user_link
		assert_equal '/people/login', users(:login).link
	end
	
	def test_user_title
		assert_equal 'Login', users(:login).title
	end
	def test_user_title_no_nickname
		assert_equal "User #{users(:minimal).id}", users(:minimal).title
	end
	
	def test_user_title_prefix
		assert_nil users(:login).title_prefix
	end
	
	# •••••••••••  TESTS TO BE WRITTEN  •••••••••••••••••••••••••••••
	
	# TODO: tests for time_zone handling
	
	# TODO: test for user not being able to willy-nilly update an email address that has been activated
	#def test_change_email
	#	# •••
	#	assert true
	#	
	#end
	
	def test_new_user
		u_attrs = {:email=>'new_test@wayground.ca',
			:nickname=>'Newbie', :fullname=>'New User', :subpath=>'new',
			:about=>'This is a new user.'}
		u = User.new(u_attrs.merge({:password=>'password',
			:password_confirmation=>'password'}))
		assert u
		u.save!
		u_attrs.each_pair do |k,v|
			assert_equal(v, u[k], :message=>" #{k} should be “#{v}”")
		end
		assert !(u.crypted_password.blank?)
		assert !(u.salt.blank?)
		assert !(u.activation_code.blank?)
	end
	def test_new_user_minimum_values
		u_attrs = {:fullname=>'Minimum Values'}
		u = User.new(u_attrs)
		assert u
		u.save!
		u_attrs.each_pair do |k,v|
			assert_equal(v, u[k], :message=>" #{k} should be “#{v}”")
		end
		assert u.crypted_password.blank?
		assert u.salt.blank?
		assert !(u.activation_code.blank?)
	end
	def test_new_user_no_values
		u = User.new()
		assert u
		assert !(u.valid?)
	end
	def test_new_user_invalid_attributes
		# invalid values for attributes
		invalid_format_attrs = {:email=>'bad email', :email=>'bad@email'}
		invalid_format_attrs.each do |k,v|
			u = User.new({k=>v})
			assert(!(u.valid?),
			 	:message=>"invalid #{k} (“#{v}”) should not validate")
		end
		# attributes that should not be settable
		dont_set_attrs = {:activation_code=>'activate', :activated_at=>Time.now,
			:admin=>true, :staff=>true, :remember_token=>'remember',
			:remember_token_expires_at=>Time.now, :login_at=>Time.now,
			:created_at=>Time.now, :updated_at=>Time.now}
		dont_set_attrs.each_pair do |k,v|
			assert_raise(Wayground::AssignToProtectedAttribute) do
				u = User.new({k=>v})
			end
			#assert_nil(u[k],
			#	:message=>"Should not allow parameter setting of #{k}")
		end
	end
	
end
