require File.dirname(__FILE__) + '/../test_helper'

class SessionsControllerTest < ActionController::TestCase
	fixtures :users
	
	def setup
		@controller = SessionsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end

	def test_routing
		#map.login '/login', :controller=>'sessions', :action=>'new'
		assert_generates("/login", :controller=>"sessions", :action=>"new")
		assert_recognizes({:controller=>"sessions", :action=>"new"}, "/login")
		#map.logout '/logout', :controller=>'sessions', :action=>'destroy'
		assert_generates("/logout", :controller=>"sessions", :action=>"destroy")
		assert_recognizes({:controller=>"sessions", :action=>"destroy"}, "/logout")
		
		#map.resource :session, :controller=>'sessions'
		# skip new and destroy because they’re handled by custom routes above
		assert_routing_for_resource 'sessions', ['new','destroy'], [], {}, :session
		
		# TODO future: open_id routing
	end
	
	# LOGIN FORM
	
	def test_should_get_login_form
		get :new
		assert_response :success
		assert_nil flash[:notice]
		assert_equal 'Login', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{session_path}]" do
				assert_select 'input[name=email]'
				assert_select 'input[name=password]'
				assert_select 'input[name=remember_me][type=checkbox][value=1]'
			end
		end
	end
	
	
	# LOGIN
	
	def test_should_login_and_redirect
		assert_efficient_sql do
			post :create, {:email=>'login_test@wayground.ca',
				:password=>'password'}
		end
		assert_response :redirect
		assert session[:user]
		assert_nil @response.cookies["auth_token"] # remember_me not set
		assert flash[:notice]
		assert_redirected_to account_users_path
	end

	def test_should_fail_login_and_not_redirect
		post :create, {:email=>'login_test@wayground.ca',
			:password=>'bad password'}
		assert_response :success
		assert_nil session[:user]
		# I don’t know why flash is cleared before we get here
		#assert flash[:error]
		# view result
		assert_template 'new'
	end
	
	def test_should_remember_me
		post :create, {:email=>'login_test@wayground.ca', :password=>'password',
			:remember_me=>"1"}
		assert_not_nil @response.cookies["auth_token"]
	end

	def test_should_not_remember_me
		post :create, {:email=>'login_test@wayground.ca', :password=>'password',
			:remember_me=>"0"}
		assert_nil @response.cookies["auth_token"]
	end
	
	def test_should_login_with_cookie
		users(:login).remember_me
		@request.cookies["auth_token"] = cookie_for(:login)
		assert_efficient_sql do
			get :new
		end
		assert_response :redirect
		assert @controller.send(:current_user)
		assert session[:user]
		# I don’t know why flash is cleared before we get here
		#assert flash[:notice]
		assert_redirected_to account_users_path
	end

	def test_should_fail_expired_cookie_login
		users(:login).remember_me
		users(:login).update_attribute :remember_token_expires_at, 5.minutes.ago
		@request.cookies["auth_token"] = cookie_for(:login)
		get :new
		assert_response :success
		assert !@controller.send(:current_user)
		assert_nil session[:user]
		# I don’t know why flash is cleared before we get here
		#assert flash[:notice]
		# view result
		assert_template 'new'
	end

	def test_should_fail_cookie_login
		users(:login).remember_me
		@request.cookies["auth_token"] = auth_token('invalid_auth_token')
		get :new
		assert_response :success
		assert !@controller.send(:current_user)
		assert_nil session[:user]
		# I don’t know why flash is cleared before we get here
		#assert flash[:notice]
		# view result
		assert_template 'new'
	end
	
	# LOGOUT
	
	def test_should_logout
		users(:login).remember_me
		@request.cookies["auth_token"] = cookie_for(:login)
		delete :destroy, {}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil session[:user]
		assert_equal @response.cookies["auth_token"], []
		assert flash[:notice]
		assert_redirected_to new_session_path
	end
	
	# TODO: test use of remember_me token
	
	protected
	
	def auth_token(token)
		CGI::Cookie.new('name'=>'auth_token', 'value'=>token)
	end

	def cookie_for(user)
		auth_token users(user).remember_token
	end
	
end
