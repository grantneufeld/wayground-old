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
	# TODO: Test set membership as admin
	# TODO: Test remove admin status from membership
	# TODO: Test set access for membership (can_add_event, can_invite, can_moderate, can_manage_members)
	# TODO: Test set title for membership
	# TODO: Test set sort (position) for membership
	# TODO: Test bulk add members to group by email (and optional name)
	# TODO: Test bulk invite members to group by email (and optional name)
	# TODO: Test batch select memberships
	# TODO: Test delete selected batch of memberships
	# TODO: Test set expiry for selected batch of memberships
	
	
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
			assert_select 'h2', assigns(:membership).user.nickname
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
	
	
	# SCENARIOS
	
	# NON-SIGNED-IN USER
	# join / invite request form (new) (renders user sign-up form / login form)
	def test_memberships_new_no_user
		get :new, {:group_id=>groups(:membered_group).subpath}, {}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		#assert assigns(:membership)
		assert assigns(:user)
		assert flash[:notice]
		assert_equal "#{assigns(:group).name}: New Membership",
			assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', "Join #{assigns(:group).name}"
			# TODO: website registration notices
			assert_select "form[action=#{group_memberships_path(assigns(:group))}]" do
				assert_select 'input#user_email'
				assert_select 'input#user_fullname'
				assert_select 'input#user_nickname'
				assert_select 'input#user_password'
				assert_select 'input#user_password_confirmation'
			end
		end
	end
	def test_memberships_new_no_user_invite
		get :new, {:group_id=>groups(:invite_only_group).subpath}, {}
		assert_response :redirect
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	# join / invite request (create) (creates User and Membership)
	def test_memberships_create_no_user
		assert_difference(Membership, :count, 0) do
			post :create, {:group_id=>groups(:membered_group).subpath,
				:user=>{:email=>'test+membership_create_no_user@wayground.ca',
					:fullname=>'Create User Membership', :nickname=>'test create',
					:password=>'password', :password_confirmation=>'password'}
				},
				{}
		end
		assert_response :redirect
		#assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership) #.is_a?(Membership)
		assert_nil assigns(:user) #.is_a?(User)
		assert flash[:warning]
		assert_redirected_to(login_path) #{:action=>'show', :id=>assigns(:membership)})
		# cleanup
		#assigns(:membership).destroy
		#assigns(:user).destroy
	end
	def test_memberships_create_no_user_invite
		assert_difference(Membership, :count, 0) do
			post :create, {:group_id=>groups(:invite_only_group).subpath,
				:user=>{:email=>'test+membership_create_no_user_invite@wayground.ca',
					:fullname=>'Create User Membership', :nickname=>'test invite req',
					:password=>'password', :password_confirmation=>'password'}
				},
				{}
		end
		assert_response :redirect
		#assert_equal groups(:invite_only_group), assigns(:group)
		assert_nil assigns(:membership) #.is_a?(Membership)
		assert_nil assigns(:user) #.is_a?(User)
		assert flash[:warning]
		assert_redirected_to(login_path) #group_membership_path(assigns(:group), assigns(:membership)))
		# cleanup
		#assigns(:membership).destroy
		#assigns(:user).destroy
	end
	# other functions login_required
	
	# USER SELF-ADMIN
	# join form (new)
	# invite request form (new)
	# join (create)
	# request invite (create)
	# (edit)
	# (update)
	# leave (destroy)
	
	# ADMIN
	# add member form (new)
	# add member (create)
	# assign access form (edit)
	# assign access (update)
	# remove (destroy)
	
	# BULK ADMIN
	# invite by email address
	# invite by user find/select
	# invite members of another group
	# add by email address
	# add by user find/select
	# add members of another group
	# batch action on selected members of group
		# - remove
		# - assign access (admin, events, can invite, moderator, manage members)
		# - block
		# - expiry date
		# - send message
	
	# NEW
	def test_memberships_new
		get :new, {:group_id=>groups(:membered_group).subpath,
			:user_id=>users(:staff).id.to_s},
			{:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert assigns(:membership)
		assert_equal users(:staff), assigns(:user)
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
				assert_select 'input#membership_user_id'
				assert_select 'input#membership_is_admin'
				assert_select 'input#membership_can_add_event'
				assert_select 'input#membership_can_invite'
				assert_select 'input#membership_can_moderate'
				assert_select 'input#membership_can_manage_members'
				assert_select 'input#membership_expires_at'
				assert_select 'input#membership_title'
			end
		end
	end
	def test_memberships_new_duplicate_user_membership
		get :new, {:group_id=>groups(:membered_group).subpath,
			:user_id=>users(:regular).id.to_s},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert assigns(:membership)
		assert flash[:notice]
		assert_redirected_to group_path(groups(:membered_group))
	end
	def test_memberships_new_user_not_permission
		get :new, {:group_id=>groups(:membered_group).subpath},
			{:user=>users(:staff).id}
#		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
#		assert_nil assigns(:membership)
#		assert flash[:warning]
#		assert_redirected_to account_users_path
	end
	def test_memberships_new_no_user
		get :new, {:group_id=>groups(:membered_group).subpath}
		assert_response :redirect
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# CREATE
	def test_memberships_create
		assert_difference(Membership, :count, 1) do
			post :create, {:group_id=>groups(:membered_group).subpath,
				:user_id=>users(:staff).id,
				:membership=>{:is_admin=>'0', :can_add_event=>'0',
					:can_invite=>'0', :can_moderate=>'0',
					:can_manage_members=>'0',
					:expires_at=>1.day.from_now.to_s(:db),
					:title=>'Test Create Membership'
					}
				},
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
		# FIXME: the scenario for membership creation has changed a lot since this test was written - need to rewrite the test
		assert_difference(Membership, :count, 0) do
			post :create, {:group_id=>groups(:membered_group).subpath},
				{:user=>users(:login).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		#assert_response :success
		#assert_equal 'groups', assigns(:section)
		#assert_equal groups(:membered_group), assigns(:group)
		#assert assigns(:membership)
		#assert_validation_errors_on(assigns(:membership), ['user'])
		#assert_nil flash[:notice]
		#assert_equal "#{assigns(:group).name}: New Membership",
		#	assigns(:page_title)
		## view result
		#assert_template 'new'
		#assert_select 'div#flash:empty'
		#assert_select 'div#content' do
		#	assert_select 'h1', assigns(:group).name
		#	assert_select 'h2', "New Membership"
		#	assert_select "form[action=#{group_memberships_path(assigns(:group))}]" do
		#		#assert_select 'input#membership_user_id'
		#		assert_select 'input#membership_is_admin'
		#		assert_select 'input#membership_can_add_event'
		#		assert_select 'input#membership_can_invite'
		#		assert_select 'input#membership_can_moderate'
		#		assert_select 'input#membership_can_manage_members'
		#		assert_select 'input#membership_expires_at'
		#		assert_select 'input#membership_title'
		#	end
		#end
	end
	def test_memberships_create_user_without_access
		assert_difference(Membership, :count, 0) do
			post :create, {:group_id=>groups(:private_group).subpath,
				:user_id=>users(:nonmember).id,
				:membership=>{:is_admin=>'0', :can_add_event=>'0',
					:can_invite=>'0', :can_moderate=>'0',
					:can_manage_members=>'0',
					:expires_at=>1.day.from_now.to_s(:db),
					:title=>'Test Create Membership Without Access'
					}
				},
				{:user=>users(:nonmember).id}
		end
		assert_response :redirect
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to group_path(groups(:private_group))
	end
	def test_memberships_create_user_block_special_settings_for_non_admins
		# TODO: test_memberships_create_user_block_special_settings_for_non_admins
	end
	# TODO: test_memberships_create_no_user
	#def test_memberships_create_no_user
	#	assert_difference(Membership, :count, 0) do
	#		post :create, {:group_id=>groups(:membered_group).subpath,
	#			:user_id=>users(:staff).id,
	#			:membership=>{:is_admin=>'0', :can_add_event=>'0',
	#				:can_invite=>'0', :can_moderate=>'0',
	#				:can_manage_members=>'0',
	#				:expires_at=>1.day.from_now.to_s(:db),
	#				:title=>'Test Create Membership No User'
	#				}
	#			},
	#			{}
	#	end
	#	assert_response :redirect
	#	assert_equal groups(:membered_group), assigns(:group)
	#	assert_nil assigns(:membership)
	#	assert flash[:warning]
	#	assert_redirected_to login_path
	#end
	
	
	# EDIT
	def test_memberships_edit
		get :edit, {:group_id=>groups(:membered_group).subpath,
			:id=>memberships(:regular).id.to_s}, {:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:regular), assigns(:membership)
		assert_nil flash[:notice]
		assert_equal "Edit Membership for #{memberships(:regular).user.nickname}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', assigns(:group).name
			assert_select 'h2', "Edit Membership for #{assigns(:membership).user.nickname}"
			assert_select "form[action='#{group_membership_path(assigns(:group), assigns(:membership))}']" do
				assert_select 'input#membership_user_id', false,
					'Edit form should not contain the user id'
				assert_select 'input#membership_is_admin'
				assert_select 'input#membership_can_add_event'
				assert_select 'input#membership_can_invite'
				assert_select 'input#membership_can_moderate'
				assert_select 'input#membership_can_manage_members'
				assert_select 'input#membership_expires_at'
				assert_select 'input#membership_title'
			end
		end
	end
	def test_memberships_edit_invalid_user
		get :edit, {:group_id=>groups(:membered_group).subpath,
			:id=>memberships(:regular).id}, {:user=>users(:staff).id}
#		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
#		assert_nil assigns(:membership)
#		assert flash[:warning]
#		assert_redirected_to account_users_path
	end
	def test_memberships_edit_no_user
		get :edit, {:group_id=>groups(:membered_group).subpath,
			:id=>memberships(:regular).id}, {}
		assert_response :redirect
		assert_nil assigns(:membership)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_memberships_edit_no_id
		assert_raise(ActionController::RoutingError) do
			get :edit, {:group_id=>groups(:membered_group).subpath},
				{:user=>users(:login).id}
		end
	end
	def test_memberships_edit_invalid_id
		get :edit, {:group_id=>groups(:membered_group).subpath, :id=>'invalid'},
			{:user=>users(:login).id}
		assert_response :missing
		assert_equal groups(:membered_group), assigns(:group)
		assert_nil assigns(:membership)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# UPDATE
	def test_memberships_update
		expires = Time.current.utc
		put :update,
			{	:group_id=>groups(:membered_group).subpath,
				:id=>memberships(:update_membership).id,
				:membership=>{
					:position=>'10',
					:is_admin=>'1',
					:can_add_event=>'1',
					:can_invite=>'1',
					:can_moderate=>'1',
					:can_manage_members=>'1',
					:expires_at=>expires.to_s,
					:title=>'Updated Membership Title'
				}
			},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:update_membership), assigns(:membership)
		assert_equal 10, assigns(:membership).position
		assert assigns(:membership).is_admin
		assert assigns(:membership).can_add_event
		assert assigns(:membership).can_invite
		assert assigns(:membership).can_moderate
		assert assigns(:membership).can_manage_members
		assert_equal expires.to_s(:db), assigns(:membership).expires_at.utc.to_s(:db)
		assert_equal 'Updated Membership Title', assigns(:membership).title
		assert flash[:notice]
		assert_redirected_to(group_membership_path(assigns(:group),
			assigns(:membership)))
	end
	def test_memberships_update_user_without_access
		original_title = memberships(:update_membership).title
		put :update, {:group_id=>groups(:membered_group).subpath,
				:id=>memberships(:update_membership).id,
				:membership=>{:title=>'Update Membership by Non Group Admin'}},
			{:user=>users(:staff).id}
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
#		assert_nil assigns(:membership)
		# membership was not updated
		assert_equal original_title, memberships(:update_membership).title
#		assert flash[:warning]
#		assert_redirected_to account_users_path
	end
	def test_memberships_update_no_user
		original_title = memberships(:update_membership).title
		put :update, {:group_id=>groups(:membered_group).subpath,
				:id=>memberships(:update_membership).id,
				:membership=>{:title=>'Update Membership with No User'}},
			{}
		assert_response :redirect
		assert_nil assigns(:membership)
		# membership was not updated
		assert_equal original_title, memberships(:update_membership).title
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_memberships_update_no_params
		original_title = memberships(:update_membership).title
		put :update, {:group_id=>groups(:membered_group).subpath,
				:id=>memberships(:update_membership).id, :membership=>{}},
			{:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:membered_group), assigns(:group)
		assert_equal memberships(:update_membership), assigns(:membership)
		# membership was not updated
		assert_equal original_title, memberships(:update_membership).title
		assert_nil flash[:notice]
		assert_equal "Edit Membership for #{memberships(:update_membership).user.nickname}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', assigns(:group).name
			assert_select 'h2', "Edit Membership for #{assigns(:membership).user.nickname}"
			assert_select "form[action='#{group_membership_path(assigns(:group), assigns(:membership))}']" do
				assert_select 'input#membership_user_id', false,
					'Edit form should not contain the user id'
				assert_select 'input#membership_is_admin'
				assert_select 'input#membership_can_add_event'
				assert_select 'input#membership_can_invite'
				assert_select 'input#membership_can_moderate'
				assert_select 'input#membership_can_manage_members'
				assert_select 'input#membership_expires_at'
				assert_select 'input#membership_title'
			end
		end
	end
	
	
	# DELETE
	def test_memberships_destroy_with_admin_user
		# create a membership to be destroyed
		membership = nil
		assert_difference(Membership, :count, 1) do
			membership = Membership.new(:title=>'Delete Membership')
			membership.group = groups(:membered_group)
			membership.user = users(:staff)
			membership.save!
		end
		# destroy the membership (and it's thumbnail)
		assert_difference(Membership, :count, -1) do
			delete :destroy, {:group_id=>groups(:membered_group).subpath,
				:id=>membership.id}, {:user=>users(:login).id}
		end
		assert_response :redirect
		assert_equal groups(:membered_group), assigns(:group)
		assert flash[:notice]
		assert_redirected_to group_memberships_path(assigns(:group))
	end
	# TODO: test_memberships_destroy_with_wrong_user
	#def test_memberships_destroy_with_wrong_user
	#	assert_difference(Membership, :count, 0) do
	#		delete :destroy, {:group_id=>groups(:membered_group).subpath,
	#			:id=>memberships(:regular).id},
	#			{:user=>users(:staff).id}
	#	end
	#	assert_response :redirect
	#	assert_equal groups(:membered_group), assigns(:group)
	#	assert_nil assigns(:membership)
	#	assert flash[:warning]
	#	assert_redirected_to account_users_path
	#end
	# TODO: test_memberships_destroy_with_no_user
	#def test_memberships_destroy_with_no_user
	#	assert_difference(Membership, :count, 0) do
	#		delete :destroy, {:group_id=>groups(:membered_group).subpath,
	#			:id=>memberships(:regular).id}, {}
	#	end
	#	assert_response :redirect
	#	assert_equal groups(:membered_group), assigns(:group)
	#	assert_nil assigns(:membership)
	#	assert flash[:warning]
	#	assert_redirected_to login_path
	#end
	def test_memberships_destroy_with_invalid_id
		assert_difference(Membership, :count, 0) do
			delete :destroy, {:group_id=>groups(:membered_group).subpath,
				:id=>'invalid'}, {:user=>users(:login).id}
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
			delete :destroy, {:group_id=>groups(:membered_group).subpath},
				{:user=>users(:login).id}
		end
	end
end
