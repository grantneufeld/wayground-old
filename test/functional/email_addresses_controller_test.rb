require 'test_helper'

class EmailAddressesControllerTest < ActionController::TestCase
	fixtures :email_addresses, :users

	def setup
		@controller = EmailAddressesController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.resources :users, :collection=>{:activate=>:get, :account=>:get} do |users|
		#	users.resources :email_addresses
		#end
		assert_routing_for_resources 'email_addresses', [], ['user'], {}, {}
		#map.resources :email_addresses
		assert_routing_for_resources 'email_addresses'
	end
	
	
	# ACTIONS
	
	# TODO: access restriction tests for email addresses controller
	
	# INDEX
	test "index" do
		#assert_efficient_sql do
			get :index, {}, {:user=>users(:admin).id}
		#end
		assert_equal 10, assigns(:email_addresses).size
		assert_nil assigns(:user)
		assert_equal 'contacts', assigns(:section)
		assert_equal 'Email Addresses', assigns(:page_title)
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for index
			assigns(:email_addresses).each do |e|
				assert_select "tr#email_address_#{e.id}"
			end
		end
	end
	test "index pagination" do
		get :index, {:page=>"2"}, {:user=>users(:admin).id}
		assert_equal 7, assigns(:email_addresses).size
		assert_equal 'Email Addresses (2)', assigns(:page_title)
	end
	test "index search" do
		get :index, {:key=>'keyword'}, {:user=>users(:admin).id}
		assert_equal 2, assigns(:email_addresses).size
		assert_equal 'contacts', assigns(:section)
		assert_equal 'Email Addresses: ‘keyword’', assigns(:page_title)
		assert_nil flash[:notice]
		assert_response :success
	end
	test "index for user" do
		#assert_efficient_sql do
			get :index, {:user_id=>email_addresses(:one).user.id}, {:user=>users(:admin).id}
		#end
		assert_equal email_addresses(:one).user, assigns(:user)
		assert_equal 2, assigns(:email_addresses).size
		assert_equal 'contacts', assigns(:section)
		assert_equal("#{email_addresses(:one).user.title}: Email Addresses",
			assigns(:page_title))
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for index for user
			assigns(:email_addresses).each do |e|
				assert_select "tr#email_address_#{e.id}"
			end
		end
	end
	
	# SHOW
	test "show" do
		assert_efficient_sql do
			get :show, {:id=>email_addresses(:one).id}, {:user=>users(:admin).id}
		end
		assert_equal email_addresses(:one), assigns(:email_address)
		assert_equal 'contacts', assigns(:section)
		assert_equal("Email Address #{email_addresses(:one).id}", assigns(:page_title))
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'p', h(email_addresses(:one).to_s)
		end
	end
	test "show invalid id" do
		#assert_efficient_sql do
			get :show, {:id=>'0'}, {:user=>users(:admin).id}
		#end
		assert_response :missing
		assert_nil assigns(:email_address)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	test "show for user" do
		assert_efficient_sql do
			get :show,
				{:user_id=>email_addresses(:one).user.id, :id=>email_addresses(:one).id},
				{:user=>users(:admin).id}
		end
		assert_equal email_addresses(:one).user, assigns(:user)
		assert_equal email_addresses(:one), assigns(:email_address)
		assert_equal 'contacts', assigns(:section)
		assert_equal("#{email_addresses(:one).user.title}: Email Address #{email_addresses(:one).id}",
			assigns(:page_title))
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'p', h(email_addresses(:one).to_s)
		end
	end
	
	# NEW
	test "new" do
		get :new, {}, {:user=>users(:admin).id}
		assert assigns(:email_address)
		assert_equal 'contacts', assigns(:section)
		assert_equal 'New Email Address', assigns(:page_title)
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{email_addresses_path}]" do
				assert_select 'input#email_address_name'
				assert_select 'input#email_address_email'
			end
		end
	end
	
	# CREATE
	test "create" do
		assert_difference(EmailAddress, :count, 1) do
			post :create, {:email_address=>{:email=>'create+test@wayground.ca',
				:name=>'Test Create Email Address'}},
				{:user=>users(:admin).id}
		end
		assert assigns(:email_address).is_a?(EmailAddress)
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to({:action=>'show', :id=>assigns(:email_address)})
		# cleanup
		assigns(:email_address).destroy
	end
	test "create no params" do
		assert_difference(EmailAddress, :count, 0) do
			post :create, {}, {:user=>users(:admin).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_validation_errors_on(assigns(:email_address), ['email'])
		assert_equal 'contacts', assigns(:section)
		assert_equal 'New Email Address', assigns(:page_title)
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{email_addresses_path}]"
		end
	end
	test "create bad params" do
		assert_difference(EmailAddress, :count, 0) do
			post :create, {:email_address=>{:email=>'bad email', :name=>'Test Bad Params',}},
				{:user=>users(:admin).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_validation_errors_on(assigns(:email_address), ['email'])
		assert_equal 'contacts', assigns(:section)
		assert_equal 'New Email Address', assigns(:page_title)
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{email_addresses_path}]"
		end
	end
	
	# EDIT
	test "edit" do
		get :edit, {:id=>email_addresses(:one).id}, {:user=>users(:admin).id}
		assert_equal email_addresses(:one), assigns(:email_address)
		assert_equal 'contacts', assigns(:section)
		assert_equal "Edit Email Address #{email_addresses(:one).id}",
			assigns(:page_title)
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{email_addresses_path}/#{email_addresses(:one).id}']" do
				assert_select 'input#email_address_name'
				assert_select 'input#email_address_email'
			end
		end
	end
	
	# UPDATE
	test "update" do
		put :update, {:id=>email_addresses(:two).id,
				:email_address=>{:email=>'update-changes+email@wayground.ca',
					:name=>'Changed Email by Update'}
			},
			{:user=>users(:admin).id}
		assert_equal email_addresses(:two), assigns(:email_address)
		assert_equal 'Changed Email by Update', assigns(:email_address).name
		assert_equal 'update-changes+email@wayground.ca', assigns(:email_address).email
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to({:action=>'show', :id=>assigns(:email_address)})
	end
	test "update invalid params" do
		original_email = email_addresses(:two).email
		put :update, {:id=>email_addresses(:two).id,
			:email_address=>{:email=>'invalid email'}},
			{:user=>users(:admin).id}
		assert_equal email_addresses(:two), assigns(:email_address)
		assert_validation_errors_on(assigns(:email_address), ['email'])
		# email_address was not updated
		assert_equal original_email, email_addresses(:two).email
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{email_addresses_path}/#{email_addresses(:two).id}']"
		end
	end
	test "update no params" do
		original_email = email_addresses(:two).email
		put :update, {:id=>email_addresses(:two).id, :email_address=>{}},
			{:user=>users(:admin).id}
		assert_equal email_addresses(:two), assigns(:email_address)
		# email_address was not updated
		assert_equal original_email, email_addresses(:two).email
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{email_addresses_path}/#{email_addresses(:two).id}']"
		end
	end
	
	# DESTROY
	test "destroy" do
		# create a email_address to be destroyed
		email_address = nil
		assert_difference(EmailAddress, :count, 1) do
			email_address = EmailAddress.new(
				{:name=>'Delete Email Address', :email=>'delete+test@wayground.ca'})
			email_address.save!
		end
		# destroy the email_address (and it's thumbnail)
		assert_difference(EmailAddress, :count, -1) do
			delete :destroy, {:id=>email_address.id}, {:user=>users(:admin).id}
		end
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to email_addresses_path
	end
	test "destroy with invalid id" do
		assert_difference(EmailAddress, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:admin).id}
		end
		assert_nil assigns(:email_address)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_response :missing
		assert_template 'paths/missing'
	end
	test "destroy with no id" do
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:admin).id}
		end
	end
end
