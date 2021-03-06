require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
	fixtures :users, :email_addresses

	def setup
		@controller = UsersController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_resource_routing
		#map.resources :users, :collection=>{:activate=>:get, :account=>:get}
		assert_routing_for_resources 'users', ['new'], [],
			{:activate=>:get, :account=>:get}
	end
	
	def test_routing
		# map.signup '/signup', :controller=>'users', :action=>'new'
		assert_generates("/signup", {:controller=>"users", :action=>"new"})
		assert_recognizes({:controller=>"users", :action=>"new"}, "/signup")
		
		#map.activate '/activate/:activation_code/:encrypt_code', :controller=>'users',
		#	:action=>'activate'
		assert_generates("/activate/code/encrypt",
			{:controller=>"users", :action=>"activate",
				:activation_code=>'code', :encrypt_code=>'encrypt'})
		assert_recognizes({:controller=>'users', :action=>'activate',
			:activation_code=>'code', :encrypt_code=>'encrypt'},
			'/activate/code/encrypt')

		# map.profile '/people/:id', :controller=>'users', :action=>'profile'
		assert_generates("/people/1",
			{:controller=>"users", :action=>"profile", :id=>'1'})
		assert_generates("/people/subpath",
			{:controller=>"users", :action=>"profile", :id=>'subpath'})
		assert_recognizes({:controller=>"users", :action=>"profile", :id=>'1'},
			"/people/1")
		assert_recognizes(
			{:controller=>"users", :action=>"profile", :id=>'subpath'},
			"/people/subpath")
	end
	
	# SIGNUP / NEW
	
	def test_signup_form
		get :new
		assert_response :success
		assert assigns(:user)
		assert_nil flash[:notice]
		assert_equal 'New User Registration', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'title',
			:text=>"#{WAYGROUND['TITLE_PREFIX']}: New User Registration",
			:count=>1
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{users_path}]" do
				assert_select 'input#user_email'
				assert_select 'input#user_password'
				assert_select 'input#user_password_confirmation'
				assert_select 'input#user_fullname'
				assert_select 'input#user_nickname'
			end
		end
	end
	
	
	# CREATE (signup submit)
	
	def test_signup_submit
		# stub the emailing method
		Notifier.expects(:deliver_signup_confirmation).returns(true)
		new_email = 'create_functional_test@wayground.ca'
		assert_difference(User, :count, 1) do
			post :create, :user=>{:email=>new_email,
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Test', :nickname=>'User Func Test'}
		end
		assert_equal new_email, assigns(:user).email
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to account_users_path
		# TODO assert email sent
	end
	def test_signup_submit_email_notification_fails
		# stub the emailing method to simulate failure
		Notifier.expects(:deliver_signup_confirmation).returns(nil)
		new_email = 'create_functional_test@wayground.ca'
		assert_difference(User, :count, 1) do
			post :create, :user=>{:email=>new_email,
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Test', :nickname=>'User Func Test'}
		end
		assert_equal new_email, assigns(:user).email
		assert flash[:error]
		assert_response :redirect
		assert_redirected_to account_users_path
		# TODO assert email sent
	end
	def test_signup_submit_invalid
		assert_no_difference(User, :count) do
			post :create, :user=>{:email=>'bad email',
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Fail', :nickname=>'User Create Fail'}
		end
		assert_response :success
		assert assigns(:user)
		assert_nil flash[:notice]
		assert_equal 'New User Registration', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{users_path}]" do
				assert_select 'input#user_email'
				assert_select 'input#user_password'
				assert_select 'input#user_password_confirmation'
				assert_select 'input#user_fullname'
				assert_select 'input#user_nickname'
			end
		end
	end
	def test_signup_submit_noargs
		assert_no_difference(User, :count) do
			post :create
		end
		assert_response :success
		assert assigns(:user)
		assert_nil flash[:notice]
		assert_equal 'New User Registration', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{users_path}]" do
				assert_select 'input#user_email'
				assert_select 'input#user_password'
				assert_select 'input#user_password_confirmation'
				assert_select 'input#user_fullname'
				assert_select 'input#user_nickname'
			end
		end
	end
	def test_user_create_invalid_method_get
		new_email = 'test+user_create_invalid_method_get@wayground.ca'
		assert_difference(User, :count, 0) do
			get :create, :user=>{:email=>new_email,
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Test', :nickname=>'Create Invalid Method'}
		end
		assert_response :redirect
		assert_redirected_to({:action=>'new'})
	end
	def test_user_create_invalid_method_put
		new_email = 'test+user_create_invalid_method_put@wayground.ca'
		assert_difference(User, :count, 0) do
			put :create, :user=>{:email=>new_email,
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Test', :nickname=>'Create Invalid Method'}
		end
		assert_response :redirect
		assert_redirected_to({:action=>'new'})
	end
	def test_user_create_spam_attempt_login
		new_email = 'test+user_create_spam_login@wayground.ca'
		assert_difference(User, :count, 0) do
			post :create, :user=>{:email=>new_email, :login=>'spamlogin',
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Spam Login Test', :nickname=>'Spam Login'}
		end
		assert_response :success
		assert assigns(:user)
		assert_equal 'User Account', assigns(:page_title)
		assert flash[:notice]
		assert_template 'account'
	end
	def test_user_create_spam_attempt_url
		new_email = 'test+user_create_spam_url@wayground.ca'
		assert_difference(User, :count, 0) do
			post :create, :user=>{:email=>new_email,
				:url=>'http://spamurl.tld/',
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Spam URL Test', :nickname=>'Spam URL'}
		end
		assert_response :success
		assert assigns(:user)
		assert_equal 'User Account', assigns(:page_title)
		assert flash[:notice]
		assert_template 'account'
	end
	def test_user_create_spam_attempt_all
		new_email = 'test+user_create_spam_all@wayground.ca'
		assert_difference(User, :count, 0) do
			post :create, :user=>{:email=>new_email,
				:login=>'spamall', :url=>'http://spamall.tld/',
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Spam All Test', :nickname=>'Spam All'}
		end
		assert_response :success
		assert assigns(:user)
		assert_equal 'User Account', assigns(:page_title)
		assert flash[:notice]
		assert_template 'account'
	end
	
	
	# ACTIVATE
	
	def test_user_activate
		e = EmailAddress.new(:email=>'activate+test@wayground.ca')
		e.save!
		u = User.new(:fullname=>'User To Activate')
		u.save!
		# activate the user
		get :activate,
			{:activation_code=>e.activation_code, :encrypt_code=>e.encrypt_code},
			{:user=>u.id}
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to account_users_path
		# user’s email address has been activated:
		assert_nil assigns(:email_address).activation_code
		assert !(assigns(:email_address).activated_at.blank?)
		assert_kind_of User, assigns(:email_address).user
	end
	def test_user_activate_no_params
		get :activate
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:notice]
		assert_redirected_to login_path
	end
	def test_user_activate_invalid_code
		# user has not been activated:
		assert !(email_addresses(:activate_this_fail).activation_code.blank?)
		assert_nil email_addresses(:activate_this_fail).activated_at
		# submit an invalid activation
		get :activate, {:activation_code=>'not the right code',
			:encrypt_code=>email_addresses(:activate_this_fail).encrypt_code},
			{:user=>users(:activate_this_fail).id}
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to account_users_path
		assert_nil assigns(:email_address)
	end
	def test_user_activate_already_activated
		assert true
	end
	
	
	# ACCOUNT
	
	def test_user_account
		get :account, {}, {:user=>users(:login).id}
		assert_response :success
		assert assigns(:user)
		assert_equal 'User Account', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'account'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', "Your Account: #{users(:login).nickname}"
		end
	end
	def test_user_account_no_user
		get :account
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	# INDEX / LIST
	
	def test_user_list
#		assert_efficient_sql do
			get :index, {}, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert assigns(:users)
		assert_equal 'User List', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'table' do
				assert_select 'tr', :count=>assigns(:users).size
			end
		end
	end
	def test_user_list_not_admin
		assert_efficient_sql do
			get :index, {}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert_nil assigns(:users)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_user_list_no_login
		get :index, {}, {}
		assert_response :redirect
		assert_nil assigns(:users)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# SHOW
	
	def test_user_show
		assert_efficient_sql do
			get :show, {:id=>users(:login).id}, {:user=>users(:admin).id}
		end
		assert_response :success
		assert assigns(:user)
		assert_equal "User: #{users(:login).title}", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', users(:login).title
		end
	end
	def test_user_show_no_id
		# should raise a routing error if calling show without an id
		assert_raise(ActionController::RoutingError) do
			get :show, {}, {:user=>users(:admin).id}
		end
	end
	def test_user_show_not_admin
		assert_efficient_sql do
			get :show, {:id=>users(:login).id}, {:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_user_show_no_login
		assert_efficient_sql do
			get :show, {:id=>users(:login).id}, {}
		end
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# PROFILE
	
	def test_user_profile_id
		assert_efficient_sql do
			get :profile, {:id=>users(:login).id}
		end
		assert_response :success
		assert assigns(:user)
		assert_equal "User: #{users(:login).title}", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'profile'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', users(:login).title
		end
	end
	def test_user_profile_subpath
		assert_efficient_sql do
			get :profile, {:id=>users(:login).subpath}
		end
		assert_response :success
		assert assigns(:user)
		assert_equal "User: #{users(:login).title}", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'profile'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', users(:login).title
		end
	end
	def test_user_profile_invalid_id
		assert_efficient_sql do
			get :profile, {:id=>'not a valid id'}
		end
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:notice]
		assert_redirected_to root_path
	end
	
	# EDIT
	
	def test_edit_user_self
		get :edit, {:id=>users(:login).id}, {:user=>users(:login).id}
		assert_response :success
		assert assigns(:user)
		assert_equal "Edit User: #{users(:login).title}",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{user_path(users(:login))}]"
			# TODO: check for user edit form fields
		end
	end
	def test_edit_user_admin
		get :edit, {:id=>users(:login).id}, {:user=>users(:admin).id}
		assert_response :success
		assert assigns(:user)
		assert_equal "Edit User: #{users(:login).title}",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{user_path(users(:login))}]"
			# TODO: check for user edit form fields
		end
	end
	def test_edit_user_not_self
		get :edit, {:id=>users(:login).id}, {:user=>users(:staff).id}
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_edit_user_no_id
		# should raise a routing error if calling edit without an id
		assert_raise(ActionController::RoutingError) do
			get :edit, {}, {:user=>users(:staff).id}
		end
	end
	def test_edit_user_invalid_id
		get :edit, {:id=>'invalid id'}, {:user=>users(:admin).id}
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:notice]
		assert_redirected_to users_path
	end
	def test_edit_user_no_login
		get :edit, {:id=>users(:login).id}, {}
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# UPDATE
	def test_update_user_self
		new_about = 'User updated self from users/update'
		c = users(:login).locations.count
		#assert_difference(users(:login).locations, :count, 1) do
			put :update, {:id=>users(:login).id,
				:user=>{:about=>new_about},
				:location=>{'0'=>{:name=>'new location from users/update'}}},
				{:user=>users(:login).id}
		#end
		assert_equal c + 1, users(:login).locations.count
		assert_equal users(:login), assigns(:user)
		assert_equal new_about, assigns(:user).about
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to account_users_path
	end
	# TODO test user update
	
	def test_user_update_invalid_method_get
		new_about = 'Invalid user update method get'
		assert_difference(Location, :count, 0) do
			get :update, {:id=>users(:login).id,
				:user=>{:about=>new_about},
				:location=>{'0'=>{:name=>'new location from users/update'}}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:user)
		assert_redirected_to({:action=>'edit', :id=>users(:login).id})
	end
	def test_user_update_invalid_method_post
		new_about = 'Invalid user update method post'
		assert_difference(Location, :count, 0) do
			post :update, {:id=>users(:login).id,
				:user=>{:about=>new_about},
				:location=>{'0'=>{:name=>'new location from users/update'}}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:user)
		assert_redirected_to({:action=>'edit', :id=>users(:login).id})
	end
	
	# CHANGE PASSWORD
	# TODO test user change password
	
	
	# CHANGE EMAIL
	# TODO test user change email
	
	
	# CHANGE ADMIN/STAFF
	# TODO test user set admin/staff status
	
	
	# DELETE
	# TODO test user deletion/removal
	
	
	# TODO: tests for time_zone handling
	
end
