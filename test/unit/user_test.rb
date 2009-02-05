require File.dirname(__FILE__) + '/../test_helper'
require 'mocha'

class UserTest < ActiveSupport::TestCase
	fixtures :users, :locations, :email_addresses
	
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
	def test_user_default_order_recent
		assert_equal 'users.updated_at DESC, users.nickname, users.id',
			User.default_order({:recent=>true})
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
	
	# I’ve added a pile of users in these tests to ensure code coverage.
	# Otherwise, most of these tests would just need 2-3 users.
	def test_user_find_best_match_for_exact_match
		match_name = 'Test User'
		users = []
		best_user = User.new(:fullname=>match_name)
		users << User.new(:fullname=>'User Test')
		users << User.new(:fullname=>'TestUser')
		users << best_user
		users << User.new(:fullname=>'UserTest')
		users << User.new(:fullname=>'No thing')
		assert_equal best_user, User.find_best_match_for(match_name, users)
	end
	def test_user_find_best_match_for_alpha_match
		match_name = 'Test User'
		users = []
		best_user = User.new(:fullname=>'testuser')
		users << User.new(:fullname=>'User Test')
		users << User.new(:fullname=>'TestUsers')
		users << best_user
		users << User.new(:fullname=>'Tes Tusers')
		users << User.new(:fullname=>'No Thing')
		assert_equal best_user, User.find_best_match_for(match_name, users)
	end
	def test_user_find_best_match_for_part_match
		match_name = 'Test User'
		users = []
		best_user = User.new(:fullname=>'A Test')
		users << User.new(:fullname=>'Something Else')
		users << User.new(:fullname=>'Teslt Usenr')
		users << best_user
		users << User.new(:fullname=>'Something')
		users << User.new(:fullname=>'No Thing')
		assert_equal best_user, User.find_best_match_for(match_name, users)
	end
	def test_user_find_best_match_for_no_match
		match_name = 'Test User'
		users = []
		users << User.new(:fullname=>'ThisOne')
		users << User.new(:fullname=>'A Thing')
		users << User.new(:fullname=>'SomeThing')
		users << User.new(:fullname=>'No Thing')
		assert_equal users[0], User.find_best_match_for(match_name, users)
	end
	def test_user_find_best_match_for_no_users
		match_name = 'Test User'
		users = []
		assert_nil User.find_best_match_for(match_name, users)
	end
	
	def test_user_find_matching_email
		assert_equal users(:login),
			User.find_matching_email({:email=>users(:login).email})
	end
	def test_user_find_matching_email_no_match
		assert_nil User.find_matching_email({:email=>'non-existent@wayground.ca'})
	end
	def test_user_find_matching_email_one_addr
		email = 'test@wayground.ca'
		user = User.new(:fullname=>'Test User')
		addr = EmailAddress.new(:email=>email)
		addr.user = user
		# stub out find to return what we want it to for this test
		User.expects(:find).returns(nil)
		EmailAddress.expects(:find).returns([addr])
		assert_equal user, User.find_matching_email({:email=>email})
	end
	def test_user_find_matching_email_multiple_addrs
		email = 'test@wayground.ca'
		user = User.new(:fullname=>'Test User')
		addr = EmailAddress.new(:email=>email)
		addr.user = user
		user2 = User.new(:fullname=>'Test User 2')
		addr2 = EmailAddress.new(:email=>email)
		addr2.user = user2
		# stub out find to return what we want it to for this test
		User.expects(:find).returns(nil)
		EmailAddress.expects(:find).returns([addr, addr2])
		assert_equal user, User.find_matching_email({:email=>email})
	end
	def test_user_find_matching_email_multiple_addrs_with_name
		email = 'test@wayground.ca'
		name = 'Test User 2'
		user = User.new(:fullname=>'Test User 1')
		addr = EmailAddress.new(:email=>email)
		addr.user = user
		user2 = User.new(:fullname=>name)
		addr2 = EmailAddress.new(:email=>email)
		addr2.user = user2
		# stub out find to return what we want it to for this test
		User.expects(:find).returns(nil)
		EmailAddress.expects(:find).returns([addr, addr2])
		assert_equal user2, User.find_matching_email({:email=>email, :name=>name})
	end
	
	def test_user_find_all_matching_email
		email = users(:login).email
		assert_equal [users(:login)], User.find_all_matching_email(email)
	end
	def test_user_find_all_matching_email_addr
		# email_addresses(:one) is linked to users(:login)
		email = email_addresses(:one).email
		assert_equal [users(:login)], User.find_all_matching_email(email)
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
	
	def test_user_display_name_for_admin
		user = User.new(:fullname=>'Full Name', :nickname=>'Nick Name')
		assert_equal 'Full Name', user.display_name_for_admin(true)
	end
	def test_user_display_name_for_admin_not_admin
		user = User.new(:fullname=>'Full Name', :nickname=>'Nick Name')
		assert_equal 'Nick Name', user.display_name_for_admin(false)
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
