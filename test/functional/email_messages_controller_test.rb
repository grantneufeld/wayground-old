require 'test_helper'

class EmailMessagesControllerTest < ActionController::TestCase
	fixtures :email_messages, :users, :groups, :recipients, :attachments

	def setup
		@controller = EmailMessagesController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.resources :email_messages
		assert_routing_for_resources 'email_messages', [], [], {}, {}
		#map.resources(:groups …) do |groups|
		#	groups.resources :emails, :controller=>:email_messages
		assert_routing_for_resources 'email_messages', [], ['group'], {}, {}, 'emails'
	end
	
	
	# ACTIONS
	
	test "index" do
		#assert_efficient_sql do
			get :index, {}, {:user=>users(:staff).id}
		#end
		assert_equal 'Messages', assigns(:page_title)
		assert_equal 'messages', assigns(:section)
		assert_nil assigns(:subsection)
		assert_equal 2, assigns(:email_messages).size
		assert_nil assigns(:group)
		assert_nil flash[:notice]
		assert_response :success
	end
	test "index view" do
		get :index, {}, {:user=>users(:staff).id}
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_events_index
			assigns(:email_messages).each do |em|
				assert_select "tr#email_message_#{em.id}"
			end
		end
	end
	test "index with key" do
		#assert_efficient_sql do
			get :index, {:key=>'keyword'}, {:user=>users(:staff).id}
		#end
		assert_equal "Messages: ‘keyword’", assigns(:page_title)
		assert_equal 1, assigns(:email_messages).size
	end
	test "index for group" do
		#assert_efficient_sql do
			get :index, {:group_id=>groups(:one).id}, {:user=>users(:staff).id}
		#end
		assert_equal groups(:one), assigns(:group)
		assert_equal "#{assigns(:group).title}: Messages", assigns(:page_title)
		assert_equal 'groups', assigns(:section)
		assert_equal 'message', assigns(:subsection)
		assert_equal 1, assigns(:email_messages).size
	end
	# TODO: test blocking of non-staff/admin
	
	# NEW
	test "new" do
		get :new, {}, {:user=>users(:staff).id}
		assert_equal 'Send Message', assigns(:page_title)
		assert_equal 'messages', assigns(:section)
		assert_nil assigns(:subsection)
		assert assigns(:email_message)
		assert_response :success
	end
	test "new view" do
		get :new, {}, {:user=>users(:staff).id}
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{email_messages_path}]" do
				assert_select 'input#email_message_from'
				#assert_select 'input#email_message_to'
				assert_select 'input#email_message_subject'
				assert_select 'textarea#email_message_content'
			end
		end
	end
	test "new for group" do
		get :new, {:group_id=>groups(:one).id}, {:user=>users(:staff).id}
		assert_equal "#{assigns(:group).title}: Send Message", assigns(:page_title)
		assert_equal 'groups', assigns(:section)
		assert_equal 'message', assigns(:subsection)
		assert assigns(:email_message)
		assert_response :success
	end
	# TODO: test blocking of non-staff/admin
	
	# CREATE
	test "create" do
		assert_difference(EmailMessage, :count, 1) do
			post :create, {:email_message=>{:from=>'test@wayground.ca',
				:to=>'test@wayground.ca',
				:subject=>'delivery test', :content=>'Delivery test.'}},
				{:user=>users(:staff).id}
		end
		assert_kind_of EmailMessage, assigns(:email_message)
		assert_equal 'sent', assigns(:email_message).status
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to({:action=>'show', :id=>assigns(:email_message)})
		## cleanup
		#assigns(:email_message).destroy
	end
	test "create with delivery failure" do
		EmailMessage.any_instance.stubs(:deliver!).raises(Wayground::DeliveryFailure)
		assert_difference(EmailMessage, :count, 1) do
			post :create, {:email_message=>{:from=>'test@wayground.ca',
				:to=>'test@wayground.ca',
				:subject=>'delivery test', :content=>'Delivery test.'}},
				{:user=>users(:staff).id}
		end
		assert_kind_of EmailMessage, assigns(:email_message)
		assert_equal 'draft', assigns(:email_message).status
		assert flash[:error]
		assert_response :success
		assert_template 'new'
	end
	# TODO: test blocking of non-staff/admin
	
	
	
	
	
end
