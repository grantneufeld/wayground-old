require 'test_helper'

class MembershipsControllerTest < ActionController::TestCase
	fixtures :memberships, :groups, :users, :locations

	def setup
		@controller = MembershipsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	def test_memberships_resource_routing
		#map.resources :groups do |groups|
		#	groups.resources :memberships
		#end
		assert_routing_for_resources 'memberships', [], ['group']
	end
	
	
	# TODO: Test memberships controller calls without group id (should fail).
	# TODO: Test private group access.
	# TODO: Test group membership expiry
	# TODO: Test group membership invitations
	# TODO: Test group membership blocking
	
	
	# INDEX (LIST)
	def test_memberships_index
		assert_efficient_sql do
			get :index, {:group_id=>groups(:membered_group).subpath}
				#, {:user=>users(:admin).id}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal 4, assigns(:memberships).size
		assert_equal "#{assigns(:group).name} Memberships", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'table' do
				assigns(:memberships).each do |m|
					assert_select "tr#membership_#{m.id}"
				end
			end
		end
	end
	def test_memberships_index_search
		assert_efficient_sql do
			get :index, {:group_id=>groups(:membered_group).subpath,
				:key=>'regular'} #, {:user=>users(:admin).id}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
#		assert_equal 1, assigns(:memberships).size
		assert_equal "#{assigns(:group).name} Memberships: ‘regular’",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'table' do
				assigns(:memberships).each do |m|
					assert_select "tr#membership_#{m.id}"
				end
			end
		end
	end


	# SHOW
	def test_memberships_show
		assert_efficient_sql do
			get :show, {:group_id=>groups(:membered_group).subpath,
				:id=>memberships(:regular).id}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert assigns(:membership)
		assert_equal("#{assigns(:group).name} Membership for #{assigns(:membership).user.nickname}", assigns(:page_title))
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', assigns(:group).name
			assert_select 'h2', "Membership Details for #{assigns(:membership).user.nickname}"
		end
	end
	def test_memberships_show_invalid_id
		#assert_efficient_sql do
			get :show, {:group_id=>groups(:membered_group).subpath, :id=>'0'}
		#end
		assert_response :missing
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# NEW
	def test_memberships_new
		get :new, {:group_id=>groups(:membered_group).subpath,
			:user_id=>users(:plain).id.to_s},
			{:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert assigns(:membership)
		assert_equal users(:plain), assigns(:user)
		assert_nil flash[:notice]
		assert_equal "#{assigns(:group).name}: New Membership",
			assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', assigns(:group).name
			assert_select 'h2', "New Membership for #{assigns(:membership).user.nickname}"
			assert_select "form[action=#{group_memberships_path(assigns(:group))}]" do
				#assert_select 'input#membership_group_id'
				#assert_select 'input#membership_position'
				assert_select 'input#membership_user_id'
				#assert_select 'input#membership_location_id'
				assert_select 'input#membership_is_admin'
				assert_select 'input#membership_can_add_event'
				assert_select 'input#membership_can_invite'
				assert_select 'input#membership_can_moderate'
				assert_select 'input#membership_can_manage_members'
				assert_select 'input#membership_expires_at'
				#assert_select 'input#membership_invited_at'
				#assert_select 'input#membership_inviter_id'
				#assert_select 'input#membership_blocked_at'
				#assert_select 'input#membership_block_expires_at'
				#assert_select 'input#membership_blocker_id'
				assert_select 'input#membership_title'
			end
		end
	end
	
	if false # •••
	
	def test_memberships_new_duplicate_user_membership
		# TODO: test where the user already has a membership
		assert true
	end
	def test_memberships_new_user_not_permission
		get :new, {:group_id=>groups(:membered_group).subpath}, {:user=>users(:plain).id}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_memberships_new_no_user
		get :new, {:group_id=>groups(:membered_group).subpath}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# CREATE
	def test_memberships_create
		assert_difference(Membership, :count, 1) do
			post :create, {:group_id=>groups(:membered_group).subpath, :membership=>{:subpath=>'test-create', :name=>'Test Create Membership',
				:description=>'Test of membership creation.'}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert assigns(:membership)
		assert assigns(:membership).is_a?(Membership)
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:membership)})
		# cleanup
		assigns(:membership).destroy
	end
	def test_memberships_create_no_params
		assert_difference(Membership, :count, 0) do
			post :create, {:group_id=>groups(:membered_group).subpath}, {:user=>users(:login).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert assigns(:membership)
		assert_validation_errors_on(assigns(:membership), ['subpath', 'name'], 1)
		assert_nil flash[:notice]
		assert_equal 'New Membership', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{group_memberships_path(assigns(:group))}]" do
				assert_select 'input#membership_is_visible'
				assert_select 'input#membership_is_public'
				assert_select 'input#membership_is_members_visible'
				assert_select 'input#membership_is_invite_only'
				assert_select 'input#membership_is_no_unsubscribe'
				assert_select 'input#membership_subpath'
				assert_select 'input#membership_name'
				assert_select 'input#membership_url'
				assert_select 'textarea#membership_description'
				assert_select 'textarea#membership_welcome'
			end
		end
	end
	def test_memberships_create_bad_params
		assert_difference(Membership, :count, 0) do
			post :create, {:group_id=>groups(:membered_group).subpath, :membership=>{:subpath=>'bad subpath', :name=>'Test Bad Params',
				:url=>'bad url', :description=>'Test of membership creation with bad params.'}},
				{:user=>users(:login).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert assigns(:membership)
		assert_validation_errors_on(assigns(:membership), ['subpath', 'url'])
		assert_nil flash[:notice]
		assert_equal 'New Membership', assigns(:page_title)
		# view result
		#debugger
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{group_memberships_path(assigns(:group))}]" do
				assert_select 'input#membership_is_visible'
				assert_select 'input#membership_is_public'
				assert_select 'input#membership_is_members_visible'
				assert_select 'input#membership_is_invite_only'
				assert_select 'input#membership_is_no_unsubscribe'
				assert_select 'input#membership_subpath'
				assert_select 'input#membership_name'
				assert_select 'input#membership_url'
				assert_select 'textarea#membership_description'
				assert_select 'textarea#membership_welcome'
			end
		end
	end
	def test_memberships_create_user_without_access
		assert_difference(Membership, :count, 0) do
			post :create, {:group_id=>groups(:membered_group).subpath, :membership=>{:subpath=>'no-access', :name=>'Test No Access',
				:description=>'Test of membership creation with invalid access.'}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_memberships_create_no_user
		assert_difference(Membership, :count, 0) do
			post :create, {:group_id=>groups(:membered_group).subpath, :membership=>{:subpath=>'no-user', :name=>'Test No User',
				:description=>'Test of membership creation with no user.'}},
				{}
		end
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# EDIT
	def test_memberships_edit
		get :edit, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:regular).subpath}, {:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:regular), assigns(:membership)
		assert_nil flash[:notice]
		assert_equal "Edit Membership: #{memberships(:regular).name}", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{group_membership_path(assigns(:group), assigns(:membership))}']" do
				assert_select 'input#membership_is_visible'
				assert_select 'input#membership_is_public'
				assert_select 'input#membership_is_members_visible'
				assert_select 'input#membership_is_invite_only'
				assert_select 'input#membership_is_no_unsubscribe'
				#assert_select 'input#membership_subpath'
				assert_select 'input#membership_name'
				assert_select 'input#membership_url'
				assert_select 'textarea#membership_description'
				assert_select 'textarea#membership_welcome'
			end
		end
	end
	def test_memberships_edit_admin
		get :edit, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:regular).subpath}, {:user=>users(:admin).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:regular), assigns(:membership)
		assert_nil flash[:notice]
		assert_equal "Edit Membership: #{memberships(:regular).name}", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{group_membership_path(assigns(:group), assigns(:membership))}']" do
				assert_select 'input#membership_is_visible'
				assert_select 'input#membership_is_public'
				assert_select 'input#membership_is_members_visible'
				assert_select 'input#membership_is_invite_only'
				assert_select 'input#membership_is_no_unsubscribe'
				#assert_select 'input#membership_subpath'
				assert_select 'input#membership_name'
				assert_select 'input#membership_url'
				assert_select 'textarea#membership_description'
				assert_select 'textarea#membership_welcome'
			end
		end
	end
	def test_memberships_edit_invalid_user
		get :edit, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:regular).subpath}, {:user=>users(:login).id}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_memberships_edit_no_user
		get :edit, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:regular).subpath}, {}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_memberships_edit_no_id
		assert_raise(ActionController::RoutingError) do
			get :edit, {:group_id=>groups(:membered_group).subpath}, {:user=>users(:login).id}
		end
	end
	def test_memberships_edit_invalid_id
		get :edit, {:group_id=>groups(:membered_group).subpath, :id=>'invalid'}, {:user=>users(:login).id}
		assert_response :missing
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# UPDATE
	def test_memberships_update
		put :update,
			{	:group_id=>groups(:membered_group).subpath,
				:id=>memberships(:update_membership).subpath,
				:membership=>{
					:is_visible=>'1',
					:is_public=>'1',
					:is_members_visible=>'1',
					:is_invite_only=>'1',
					:is_no_unsubscribe=>'1',
					#:subpath=>'changed-subpath',
					:name=>'Updated Membership Name',
					:url=>'http://wayground.ca/test/updated-membership',
					:description=>'This membership has been updated.',
					:welcome=>'Welcome to the updated membership.'
				}
			},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:update_membership), assigns(:membership)
		assert assigns(:membership).is_visible
		assert assigns(:membership).is_public
		assert assigns(:membership).is_members_visible
		assert assigns(:membership).is_invite_only
		assert assigns(:membership).is_no_unsubscribe
		assert_equal 'Updated Membership Name', assigns(:membership).name
		assert_equal 'http://wayground.ca/test/updated-membership', assigns(:membership).url
		assert_equal 'This membership has been updated.', assigns(:membership).description
		assert_equal 'Welcome to the updated membership.', assigns(:membership).welcome
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:membership)})
	end
	def test_memberships_update_admin
		put :update,
			{	:group_id=>groups(:membered_group).subpath,
				:id=>memberships(:update_membership).subpath,
				:membership=>{
					:is_visible=>'1',
					:is_public=>'1',
					:is_members_visible=>'1',
					:is_invite_only=>'1',
					:is_no_unsubscribe=>'1',
					#:subpath=>'changed-subpath',
					:name=>'Updated Membership Name',
					:url=>'http://wayground.ca/test/updated-membership',
					:description=>'This membership has been updated.',
					:welcome=>'Welcome to the updated membership.'
				}
			},
			{:user=>users(:admin).id}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:update_membership), assigns(:membership)
		assert assigns(:membership).is_visible
		assert assigns(:membership).is_public
		assert assigns(:membership).is_members_visible
		assert assigns(:membership).is_invite_only
		assert assigns(:membership).is_no_unsubscribe
		assert_equal 'Updated Membership Name', assigns(:membership).name
		assert_equal 'http://wayground.ca/test/updated-membership', assigns(:membership).url
		assert_equal 'This membership has been updated.', assigns(:membership).description
		assert_equal 'Welcome to the updated membership.', assigns(:membership).welcome
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:membership)})
	end
	def test_memberships_update_non_group_admin_or_admin_user
		original_name = memberships(:update_membership).name
		put :update, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:update_membership).subpath,
			:membership=>{:name=>'Update Membership by Non Group Admin'}},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		# membership was not updated
		assert_equal original_name, memberships(:update_membership).name
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_memberships_update_no_user
		original_name = memberships(:update_membership).name
		put :update, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:update_membership).subpath,
			:membership=>{:name=>'Update Membership with No User'}},
			{}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		# membership was not updated
		assert_equal original_name, memberships(:update_membership).name
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_memberships_update_invalid_params
		original_name = memberships(:update_membership).name
		put :update, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:update_membership).subpath,
			:membership=>{:url=>'invalid url'}},
			{:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:update_membership), assigns(:membership)
		assert_validation_errors_on(assigns(:membership), ['url'])
		# membership was not updated
		assert_equal original_name, memberships(:update_membership).name
		assert_nil flash[:notice]
		assert_equal "Edit Membership: #{memberships(:update_membership).name}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{group_membership_path(assigns(:group), assigns(:membership))}']" do
				assert_select 'input#membership_is_visible'
				assert_select 'input#membership_is_public'
				assert_select 'input#membership_is_members_visible'
				assert_select 'input#membership_is_invite_only'
				assert_select 'input#membership_is_no_unsubscribe'
				#assert_select 'input#membership_subpath'
				assert_select 'input#membership_name'
				assert_select 'input#membership_url'
				assert_select 'textarea#membership_description'
				assert_select 'textarea#membership_welcome'
			end
		end
	end
	def test_memberships_update_no_params
		original_name = memberships(:update_membership).name
		put :update, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:update_membership).subpath, :membership=>{}},
			{:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:update_membership), assigns(:membership)
		# membership was not updated
		assert_equal original_name, memberships(:update_membership).name
		assert_nil flash[:notice]
		assert_equal "Edit Membership: #{memberships(:update_membership).name}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{group_membership_path(assigns(:group), assigns(:membership))}']" do
				assert_select 'input#membership_is_visible'
				assert_select 'input#membership_is_public'
				assert_select 'input#membership_is_members_visible'
				assert_select 'input#membership_is_invite_only'
				assert_select 'input#membership_is_no_unsubscribe'
				#assert_select 'input#membership_subpath'
				assert_select 'input#membership_name'
				assert_select 'input#membership_url'
				assert_select 'textarea#membership_description'
				assert_select 'textarea#membership_welcome'
			end
		end
	end
	
	
	# DELETE
	def test_memberships_destroy_with_admin_user
		# create a membership to be destroyed
		membership = nil
		assert_difference(Membership, :count, 1) do
			membership = Membership.new({:name=>'Delete Membership', :subpath=>'delete-membership'})
			membership.creator = users(:login)
			membership.owner = users(:login)
			membership.save!
		end
		# destroy the membership (and it's thumbnail)
		assert_difference(Membership, :count, -1) do
			delete :destroy, {:group_id=>groups(:membered_group).subpath, :id=>membership.subpath}, {:user=>users(:admin).id}
		end
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert flash[:notice]
		assert_redirected_to group_memberships_path(assigns(:group))
	end
	def test_memberships_destroy_with_group_admin_user
		# create a membership to be destroyed
		membership = nil
		assert_difference(Membership, :count, 1) do
			membership = Membership.new({:name=>'Delete Membership', :subpath=>'delete-membership'})
			membership.creator = users(:login)
			membership.owner = users(:login)
			membership.save!
		end
		# destroy the membership (and it's thumbnail)
		assert_difference(Membership, :count, -1) do
			delete :destroy, {:group_id=>groups(:membered_group).subpath, :id=>membership.subpath}, {:user=>users(:login).id}
		end
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert flash[:notice]
		assert_redirected_to group_memberships_path(assigns(:group))
	end
	def test_memberships_destroy_with_wrong_user
		assert_difference(Membership, :count, 0) do
			delete :destroy, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:regular).subpath},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_memberships_destroy_with_no_user
		assert_difference(Membership, :count, 0) do
			delete :destroy, {:group_id=>groups(:membered_group).subpath, :id=>memberships(:regular).subpath}, {}
		end
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_memberships_destroy_with_invalid_id
		assert_difference(Membership, :count, 0) do
			delete :destroy, {:group_id=>groups(:membered_group).subpath, :id=>'invalid'}, {:user=>users(:login).id}
		end
		assert_response :missing
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	def test_memberships_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {:group_id=>groups(:membered_group).subpath}, {:user=>users(:login).id}
		end
	end
	
	end # ••• if false
end
