require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
	fixtures :users #, :contacts

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
		
		#map.activate '/activate/:activation_code', :controller=>'users',
		#	:action=>'activate'
		assert_generates("/activate/code",
			{:controller=>"users", :action=>"activate",
				:activation_code=>'code'})
		assert_recognizes({:controller=>"users", :action=>"activate",
			:activation_code=>'code'}, "/activate/code")

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
#••		assert_select 'title', :text=>"#{WAYGROUND['TITLE_PREFIX']}: Groups",
#••			:count=>1
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
		new_email = 'create_functional_test@wayground.ca'
		assert_difference(User, :count, 1) do
			post :create, :user=>{ :email=>new_email,
				:password=>'password', :password_confirmation=>'password',
				:fullname=>'User Controller Test', :nickname=>'User Func Test'}
		end
		assert_response :redirect
		assert assigns(:user)
		assert_equal new_email, assigns(:user).email
		assert flash[:notice]
		assert_redirected_to account_users_path
		# TODO assert email sent
	end
	def test_signup_submit_invalid
		assert_no_difference(User, :count) do
			post :create, :user=>{ :email=>'bad email',
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
	
	
	# ACTIVATE
	
	def test_user_activate
		# user has not been activated:
		assert !(users(:activate_this).activation_code.blank?)
		assert_nil users(:activate_this).activated_at
		# activate the user
		get :activate,
			{:activation_code=>users(:activate_this).activation_code},
			{:user=>users(:activate_this).id}
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to account_users_path
		# user has been activated:
		assert assigns(:user)
		assert_nil assigns(:user).activation_code
		assert !(assigns(:user).activated_at.blank?)
	end
	def test_user_activate_no_params
		get :activate
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_user_activate_invalid_code
		# user has not been activated:
		assert !(users(:activate_this_fail).activation_code.blank?)
		assert_nil users(:activate_this_fail).activated_at
		# submit an invalid activation
		get :activate, {:activation_code=>'not the right code'},
			{:user=>users(:activate_this_fail).id}
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to account_users_path
		# user should still not be activated:
		assert assigns(:user)
		assert !(assigns(:user).activation_code.blank?)
		assert_nil assigns(:user).activated_at
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
		assert_efficient_sql do
			get :index, {}, {:user=>users(:admin).id}
		end
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
		assert_equal "User: #{users(:login).display_name}", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', users(:login).display_name
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
		assert_equal "User: #{users(:login).display_name}", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'profile'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', users(:login).display_name
		end
	end
	def test_user_profile_subpath
		assert_efficient_sql do
			get :profile, {:id=>users(:login).subpath}
		end
		assert_response :success
		assert assigns(:user)
		assert_equal "User: #{users(:login).display_name}", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'profile'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', users(:login).display_name
		end
	end
	def test_user_profile_invalid_id
		assert_efficient_sql do
			get :profile, {:id=>'not a valid id'}
		end
		assert_response :redirect
		assert_nil assigns(:user)
		assert flash[:notice]
		assert_redirected_to home_path
	end
	
	# EDIT
	
	def test_edit_user_self
		get :edit, {:id=>users(:login).id}, {:user=>users(:login).id}
		assert_response :success
		assert assigns(:user)
		assert_equal "Edit User: #{users(:login).display_name}",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{user_path(users(:login))}]"
			#•••
		end
	end
	def test_edit_user_admin
		get :edit, {:id=>users(:login).id}, {:user=>users(:admin).id}
		assert_response :success
		assert assigns(:user)
		assert_equal "Edit User: #{users(:login).display_name}",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{user_path(users(:login))}]"
			#•••
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
	# TODO test user update
	
	
	# CHANGE PASSWORD
	# TODO test user change password
	
	
	# CHANGE EMAIL
	# TODO test user change email
	
	
	# CHANGE ADMIN/STAFF
	# TODO test user set admin/staff status
	
	
	# DELETE
	# TODO test user deletion/removal
	
	
end
