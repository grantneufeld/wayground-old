require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
	fixtures :groups, :users, :locations

	def setup
		@controller = GroupsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	def test_groups_resource_routing
		# map.resources :groups
		assert_routing_for_resources 'groups', [], [], {}
	end
	
	
	# INDEX (LIST)
	def test_groups_index
#		assert_efficient_sql do
			get :index #, {}, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal 6, assigns(:groups).size
		assert_equal 'Groups', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_groups_index
			assigns(:groups).each do |g|
				assert_select "li#group_#{g.id}"
			end
		end
	end
	def test_groups_index_search
#		assert_efficient_sql do
			get :index, {:key=>'keyword'} #, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal 2, assigns(:groups).size
		assert_equal 'Groups: ‘keyword’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_groups_index_search
			assigns(:groups).each do |g|
				assert_select "li#group_#{g.id}"
			end
		end
	end


	# SHOW
	def test_groups_show
		assert_efficient_sql do
			get :show, {:id=>groups(:one).subpath}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:one), assigns(:group)
		assert_equal("Group: #{groups(:one).name}", assigns(:page_title))
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', groups(:one).name
		end
	end
	def test_groups_show_invalid_id
		#assert_efficient_sql do
			get :show, {:id=>'0'}
		#end
		assert_response :missing
		assert_nil assigns(:group)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	def test_groups_show_for_member_user
		assert_efficient_sql do
			get :show, {:id=>groups(:membered_group).subpath},
				{:user=>users(:regular).id}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:regular), assigns(:membership)
		assert_equal("Group: #{groups(:membered_group).name}",
			assigns(:page_title))
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', groups(:membered_group).name
		end
	end
	
	
	# NEW
	def test_groups_new
		get :new, {}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert assigns(:group)
		assert_nil flash[:notice]
		assert_equal 'New Group', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{groups_path}]" do
				assert_select 'input#group_is_visible'
				assert_select 'input#group_is_public'
				assert_select 'input#group_is_members_visible'
				assert_select 'input#group_is_invite_only'
				assert_select 'input#group_is_no_unsubscribe'
				assert_select 'input#group_subpath'
				assert_select 'input#group_name'
				assert_select 'input#group_url'
				assert_select 'textarea#group_description'
				assert_select 'textarea#group_welcome'
			end
		end
	end
	def test_groups_new_user_not_staff
		get :new, {}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_groups_new_no_user
		get :new
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# CREATE
	def test_groups_create
		assert_difference(Group, :count, 1) do
			post :create, {:group=>{:subpath=>'test-create', :name=>'Test Create Group',
				:description=>'Test of group creation.'}},
				{:user=>users(:staff).id}
		end
		assert_response :redirect
		assert assigns(:group)
		assert assigns(:group).is_a?(Group)
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:group)})
		# cleanup
		assigns(:group).destroy
	end
	def test_groups_create_no_params
		assert_difference(Group, :count, 0) do
			post :create, {}, {:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert assigns(:group)
		assert_validation_errors_on(assigns(:group), ['subpath', 'name'])
		assert_nil flash[:notice]
		assert_equal 'New Group', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{groups_path}]" do
				assert_select 'input#group_is_visible'
				assert_select 'input#group_is_public'
				assert_select 'input#group_is_members_visible'
				assert_select 'input#group_is_invite_only'
				assert_select 'input#group_is_no_unsubscribe'
				assert_select 'input#group_subpath'
				assert_select 'input#group_name'
				assert_select 'input#group_url'
				assert_select 'textarea#group_description'
				assert_select 'textarea#group_welcome'
			end
		end
	end
	def test_groups_create_bad_params
		assert_difference(Group, :count, 0) do
			post :create, {:group=>{:subpath=>'bad subpath', :name=>'Test Bad Params',
				:url=>'bad url', :description=>'Test of group creation with bad params.'}},
				{:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert assigns(:group)
		assert_validation_errors_on(assigns(:group), ['subpath', 'url'])
		assert_nil flash[:notice]
		assert_equal 'New Group', assigns(:page_title)
		# view result
		#debugger
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{groups_path}]" do
				assert_select 'input#group_is_visible'
				assert_select 'input#group_is_public'
				assert_select 'input#group_is_members_visible'
				assert_select 'input#group_is_invite_only'
				assert_select 'input#group_is_no_unsubscribe'
				assert_select 'input#group_subpath'
				assert_select 'input#group_name'
				assert_select 'input#group_url'
				assert_select 'textarea#group_description'
				assert_select 'textarea#group_welcome'
			end
		end
	end
	def test_groups_create_user_without_access
		assert_difference(Group, :count, 0) do
			post :create, {:group=>{:subpath=>'no-access', :name=>'Test No Access',
				:description=>'Test of group creation with invalid access.'}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:group)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_groups_create_no_user
		assert_difference(Group, :count, 0) do
			post :create, {:group=>{:subpath=>'no-user', :name=>'Test No User',
				:description=>'Test of group creation with no user.'}},
				{}
		end
		assert_response :redirect
		assert_nil assigns(:group)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# EDIT
	def test_groups_edit
		get :edit, {:id=>groups(:three).subpath}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:three), assigns(:group)
		assert_nil flash[:notice]
		assert_equal "Edit Group: #{groups(:three).name}", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{groups_path()}/#{groups(:three).subpath}']" do
				assert_select 'input#group_is_visible'
				assert_select 'input#group_is_public'
				assert_select 'input#group_is_members_visible'
				assert_select 'input#group_is_invite_only'
				assert_select 'input#group_is_no_unsubscribe'
				#assert_select 'input#group_subpath'
				assert_select 'input#group_name'
				assert_select 'input#group_url'
				assert_select 'textarea#group_description'
				assert_select 'textarea#group_welcome'
			end
		end
	end
	def test_groups_edit_admin
		get :edit, {:id=>groups(:two).subpath}, {:user=>users(:admin).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:two), assigns(:group)
		assert_nil flash[:notice]
		assert_equal "Edit Group: #{groups(:two).name}", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{groups_path()}/#{groups(:two).subpath}']" do
				assert_select 'input#group_is_visible'
				assert_select 'input#group_is_public'
				assert_select 'input#group_is_members_visible'
				assert_select 'input#group_is_invite_only'
				assert_select 'input#group_is_no_unsubscribe'
				#assert_select 'input#group_subpath'
				assert_select 'input#group_name'
				assert_select 'input#group_url'
				assert_select 'textarea#group_description'
				assert_select 'textarea#group_welcome'
			end
		end
	end
	def test_groups_edit_invalid_user
		get :edit, {:id=>groups(:two).subpath}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:group)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_groups_edit_no_user
		get :edit, {:id=>groups(:two).subpath}, {}
		assert_response :redirect
		assert_nil assigns(:group)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_groups_edit_no_id
		assert_raise(ActionController::RoutingError) do
			get :edit, {}, {:user=>users(:staff).id}
		end
	end
	def test_groups_edit_invalid_id
		get :edit, {:id=>'invalid'}, {:user=>users(:staff).id}
		assert_response :missing
		assert_nil assigns(:group)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# UPDATE
	def test_groups_update
		put :update,
			{
				:id=>groups(:update_group).subpath,
				:group=>{
					:is_visible=>'1',
					:is_public=>'1',
					:is_members_visible=>'1',
					:is_invite_only=>'1',
					:is_no_unsubscribe=>'1',
					#:subpath=>'changed-subpath',
					:name=>'Updated Group Name',
					:url=>'http://wayground.ca/test/updated-group',
					:description=>'This group has been updated.',
					:welcome=>'Welcome to the updated group.'
				}
			},
			{:user=>users(:staff).id}
		assert_response :redirect
		assert_equal groups(:update_group), assigns(:group)
		assert assigns(:group).is_visible
		assert assigns(:group).is_public
		assert assigns(:group).is_members_visible
		assert assigns(:group).is_invite_only
		assert assigns(:group).is_no_unsubscribe
		assert_equal 'Updated Group Name', assigns(:group).name
		assert_equal 'http://wayground.ca/test/updated-group', assigns(:group).url
		assert_equal 'This group has been updated.', assigns(:group).description
		assert_equal 'Welcome to the updated group.', assigns(:group).welcome
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:group)})
	end
	def test_groups_update_admin
		put :update,
			{
				:id=>groups(:update_group).subpath,
				:group=>{
					:is_visible=>'1',
					:is_public=>'1',
					:is_members_visible=>'1',
					:is_invite_only=>'1',
					:is_no_unsubscribe=>'1',
					#:subpath=>'changed-subpath',
					:name=>'Updated Group Name',
					:url=>'http://wayground.ca/test/updated-group',
					:description=>'This group has been updated.',
					:welcome=>'Welcome to the updated group.'
				}
			},
			{:user=>users(:admin).id}
		assert_response :redirect
		assert_equal groups(:update_group), assigns(:group)
		assert assigns(:group).is_visible
		assert assigns(:group).is_public
		assert assigns(:group).is_members_visible
		assert assigns(:group).is_invite_only
		assert assigns(:group).is_no_unsubscribe
		assert_equal 'Updated Group Name', assigns(:group).name
		assert_equal 'http://wayground.ca/test/updated-group', assigns(:group).url
		assert_equal 'This group has been updated.', assigns(:group).description
		assert_equal 'Welcome to the updated group.', assigns(:group).welcome
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:group)})
	end
	def test_groups_update_non_staff_or_admin_user
		original_name = groups(:update_group).name
		put :update, {:id=>groups(:update_group).subpath,
			:group=>{:name=>'Update Group by Non Staff'}},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:group)
		# group was not updated
		assert_equal original_name, groups(:update_group).name
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_groups_update_no_user
		original_name = groups(:update_group).name
		put :update, {:id=>groups(:update_group).subpath,
			:group=>{:name=>'Update Group with No User'}},
			{}
		assert_response :redirect
		assert_nil assigns(:group)
		# group was not updated
		assert_equal original_name, groups(:update_group).name
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_groups_update_invalid_params
		original_name = groups(:update_group).name
		put :update, {:id=>groups(:update_group).subpath,
			:group=>{:url=>'invalid url'}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:update_group), assigns(:group)
		assert_validation_errors_on(assigns(:group), ['url'])
		# group was not updated
		assert_equal original_name, groups(:update_group).name
		assert_nil flash[:notice]
		assert_equal "Edit Group: #{groups(:update_group).name}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{groups_path}/#{groups(:update_group).subpath}']" do
				assert_select 'input#group_is_visible'
				assert_select 'input#group_is_public'
				assert_select 'input#group_is_members_visible'
				assert_select 'input#group_is_invite_only'
				assert_select 'input#group_is_no_unsubscribe'
				#assert_select 'input#group_subpath'
				assert_select 'input#group_name'
				assert_select 'input#group_url'
				assert_select 'textarea#group_description'
				assert_select 'textarea#group_welcome'
			end
		end
	end
	def test_groups_update_no_params
		original_name = groups(:update_group).name
		put :update, {:id=>groups(:update_group).subpath, :group=>{}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:update_group), assigns(:group)
		# group was not updated
		assert_equal original_name, groups(:update_group).name
		assert_nil flash[:notice]
		assert_equal "Edit Group: #{groups(:update_group).name}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{groups_path}/#{groups(:update_group).subpath}']" do
				assert_select 'input#group_is_visible'
				assert_select 'input#group_is_public'
				assert_select 'input#group_is_members_visible'
				assert_select 'input#group_is_invite_only'
				assert_select 'input#group_is_no_unsubscribe'
				#assert_select 'input#group_subpath'
				assert_select 'input#group_name'
				assert_select 'input#group_url'
				assert_select 'textarea#group_description'
				assert_select 'textarea#group_welcome'
			end
		end
	end
	
	
	# DELETE
	def test_groups_destroy_with_admin_user
		# create a group to be destroyed
		group = nil
		assert_difference(Group, :count, 1) do
			group = Group.new({:name=>'Delete Group', :subpath=>'delete-group'})
			group.creator = users(:login)
			group.owner = users(:login)
			group.save!
		end
		# destroy the group (and it's thumbnail)
		assert_difference(Group, :count, -1) do
			delete :destroy, {:id=>group.subpath}, {:user=>users(:admin).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to groups_path
	end
	def test_groups_destroy_with_staff_user
		# create a group to be destroyed
		group = nil
		assert_difference(Group, :count, 1) do
			group = Group.new({:name=>'Delete Group', :subpath=>'delete-group'})
			group.creator = users(:login)
			group.owner = users(:login)
			group.save!
		end
		# destroy the group (and it's thumbnail)
		assert_difference(Group, :count, -1) do
			delete :destroy, {:id=>group.subpath}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to groups_path
	end
	def test_groups_destroy_with_wrong_user
		assert_difference(Group, :count, 0) do
			delete :destroy, {:id=>groups(:three).subpath},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:group)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_groups_destroy_with_no_user
		assert_difference(Group, :count, 0) do
			delete :destroy, {:id=>groups(:two).subpath}, {}
		end
		assert_response :redirect
		assert_nil assigns(:group)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_groups_destroy_with_invalid_id
		assert_difference(Group, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:staff).id}
		end
		assert_response :missing
		assert_nil assigns(:group)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	def test_groups_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:staff).id}
		end
	end
end
