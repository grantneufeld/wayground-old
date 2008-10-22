require 'test_helper'

class WeblinksControllerTest < ActionController::TestCase
	fixtures :weblinks, :users, :groups

	def setup
		@controller = WeblinksController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	def test_resource_routing
		# map.resources :weblinks
		assert_routing_for_resources 'weblinks', [], [], {}
	end


	# INDEX (LIST)
	def test_weblinks_index
		assert_efficient_sql do
			get :index, {:group_id=>groups(:public_group).subpath}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:public_group), assigns(:item)
		assert_equal 2, assigns(:weblinks).size
		assert_equal "#{assigns(:item).display_name} Weblinks",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			#assert_select 'table' do
			#	assigns(:weblinks).each do |m|
			#		assert_select "tr#weblink_#{m.id}"
			#	end
			#end
		end
	end
	
	
	# SHOW
	def test_weblinks_show
		assert_efficient_sql do
			get :show, {:group_id=>groups(:public_group).subpath,
				:id=>weblinks(:one).id}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:public_group), assigns(:item)
		assert assigns(:weblink)
		assert_equal("#{assigns(:item).display_name}: Weblink ‘#{assigns(:weblink).title}’",
			assigns(:page_title))
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			#assert_select 'h1', assigns(:item).display_name
			#assert_select 'h2', "Weblink Details"
		end
	end
	def test_weblinks_show_invalid_id
		assert_efficient_sql do
			get :show, {:group_id=>groups(:public_group).subpath, :id=>'0'}
		end
		assert_response :missing
		assert_equal groups(:public_group), assigns(:item)
		assert_nil assigns(:weblink)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# NEW
	def test_weblinks_new
		get :new, {:group_id=>groups(:public_group).subpath},
			{:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:public_group), assigns(:item)
		assert assigns(:weblink)
		assert_equal users(:login), assigns(:weblink).user
		assert_nil flash[:notice]
		assert_equal "#{assigns(:item).display_name}: New Weblink",
			assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			#assert_select 'h1', assigns(:item).display_name
			#assert_select 'h2', "New Weblink"
			#assert_select "form[action=#{weblinks_path(assigns(:item))}]" do
			#	assert_select 'input#weblink_user_id'
			#	assert_select 'input#weblink_is_admin'
			#	assert_select 'input#weblink_can_add_event'
			#	assert_select 'input#weblink_can_invite'
			#	assert_select 'input#weblink_can_moderate'
			#	assert_select 'input#weblink_can_manage_members'
			#	assert_select 'input#weblink_expires_at'
			#	assert_select 'input#weblink_title'
			#end
		end
	end
	def test_weblinks_new_user_not_permission
		get :new, {:group_id=>groups(:public_group).subpath},
			{:user=>users(:activate_this).id}
		assert_response :redirect
		assert_nil assigns(:item)
		assert_nil assigns(:weblink)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_weblinks_new_no_user
		get :new, {:group_id=>groups(:public_group).subpath}
		assert_response :redirect
		assert_nil assigns(:item)
		assert_nil assigns(:weblink)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# CREATE
	def test_weblinks_create
		assert_difference(Weblink, :count, 1) do
			post :create, {:group_id=>groups(:public_group).subpath,
				:weblink=>{:position=>'23', :category=>'testing',
					:title=>'Test Create Weblink',
					:url=>'http://wayground.ca/weblink/test/create',
				  	:description=>'A test link for the create action'
					}
				},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_equal groups(:public_group), assigns(:item)
		assert assigns(:weblink)
		assert assigns(:weblink).is_a?(Weblink)
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:weblink)})
		# cleanup
		assigns(:weblink).destroy
	end
	def test_weblinks_create_no_params
		assert_difference(Weblink, :count, 0) do
			post :create, {:group_id=>groups(:public_group).subpath},
				{:user=>users(:login).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:public_group), assigns(:item)
		assert assigns(:weblink)
		assert_validation_errors_on(assigns(:weblink), ['url'])
		assert_nil flash[:notice]
		assert_equal "#{assigns(:item).display_name}: New Weblink",
			assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			#assert_select 'h1', assigns(:item).name
			#assert_select 'h2', "New Weblink"
			#assert_select "form[action=#{group_weblinks_path(assigns(:item))}]" do
			#	#assert_select 'input#weblink_user_id'
			#	assert_select 'input#weblink_is_admin'
			#	assert_select 'input#weblink_can_add_event'
			#	assert_select 'input#weblink_can_invite'
			#	assert_select 'input#weblink_can_moderate'
			#	assert_select 'input#weblink_can_manage_members'
			#	assert_select 'input#weblink_expires_at'
			#	assert_select 'input#weblink_title'
			#end
		end
	end
	def test_weblinks_create_user_without_access
		assert_difference(Weblink, :count, 0) do
			post :create, {:group_id=>groups(:private_group).subpath,
				:weblink=>{:category=>'testing',
					:title=>'Test Create Weblink Without Access',
					:url=>'http://wayground.ca/weblink/test/create_no_access',
				  	:description=>'Testing create action without access'
					}
				},
				{:user=>users(:nonmember).id}
		end
		assert_response :redirect
		assert_nil assigns(:weblink)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_weblinks_create_no_user
		assert_difference(Weblink, :count, 0) do
			post :create, {:group_id=>groups(:public_group).subpath,
				:weblink=>{:category=>'testing',
					:title=>'Test Create Weblink With No User',
					:url=>'http://wayground.ca/weblink/test/create_no_user',
				  	:description=>'Testing create action without user'
					}
				},
				{}
		end
		assert_response :redirect
		assert_nil assigns(:item)
		assert_nil assigns(:weblink)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	#	••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
	if false
	# EDIT
	def test_weblinks_edit
		get :edit, {:group_id=>groups(:public_group).subpath,
			:id=>weblinks(:regular).id.to_s}, {:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:public_group), assigns(:item)
		assert_equal weblinks(:regular), assigns(:weblink)
		assert_nil flash[:notice]
		assert_equal "Edit Weblink for #{weblinks(:regular).user.nickname}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			#assert_select 'h1', assigns(:item).display_name
			#assert_select 'h2', "Edit Weblink for #{assigns(:weblink).user.nickname}"
			#assert_select "form[action='#{group_weblink_path(assigns(:item), assigns(:weblink))}']" do
			#	assert_select 'input#weblink_user_id', false,
			#		'Edit form should not contain the user id'
			#	assert_select 'input#weblink_is_admin'
			#	assert_select 'input#weblink_can_add_event'
			#	assert_select 'input#weblink_can_invite'
			#	assert_select 'input#weblink_can_moderate'
			#	assert_select 'input#weblink_can_manage_members'
			#	assert_select 'input#weblink_expires_at'
			#	assert_select 'input#weblink_title'
			#end
		end
	end
	def test_weblinks_edit_invalid_user
		get :edit, {:group_id=>groups(:public_group).subpath,
			:id=>weblinks(:regular).id}, {:user=>users(:staff).id}
		assert_response :redirect
		assert_equal groups(:public_group), assigns(:item)
		assert_nil assigns(:weblink)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_weblinks_edit_no_user
		get :edit, {:group_id=>groups(:public_group).subpath,
			:id=>weblinks(:regular).id}, {}
		assert_response :redirect
		assert_equal groups(:public_group), assigns(:item)
		assert_nil assigns(:weblink)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_weblinks_edit_no_id
		assert_raise(ActionController::RoutingError) do
			get :edit, {:group_id=>groups(:public_group).subpath},
				{:user=>users(:login).id}
		end
	end
	def test_weblinks_edit_invalid_id
		get :edit, {:group_id=>groups(:public_group).subpath, :id=>'invalid'},
			{:user=>users(:login).id}
		assert_response :missing
		assert_equal groups(:public_group), assigns(:item)
		assert_nil assigns(:weblink)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# UPDATE
	def test_weblinks_update
		expires = Time.current.utc
		put :update,
			{	:group_id=>groups(:public_group).subpath,
				:id=>weblinks(:update_weblink).id,
				:weblink=>{
					:position=>'10',
					:is_admin=>'1',
					:can_add_event=>'1',
					:can_invite=>'1',
					:can_moderate=>'1',
					:can_manage_members=>'1',
					:expires_at=>expires.to_s,
					:title=>'Updated Weblink Title'
				}
			},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_equal groups(:public_group), assigns(:item)
		assert_equal weblinks(:update_weblink), assigns(:weblink)
		assert_equal 10, assigns(:weblink).position
		assert assigns(:weblink).is_admin
		assert assigns(:weblink).can_add_event
		assert assigns(:weblink).can_invite
		assert assigns(:weblink).can_moderate
		assert assigns(:weblink).can_manage_members
		assert_equal expires.to_s, assigns(:weblink).expires_at.utc.to_s
		assert_equal 'Updated Weblink Title', assigns(:weblink).title
		assert flash[:notice]
		assert_redirected_to(group_weblink_path(assigns(:item),
			assigns(:weblink)))
	end
	def test_weblinks_update_user_without_access
		original_title = weblinks(:update_weblink).title
		put :update, {:group_id=>groups(:public_group).subpath,
				:id=>weblinks(:update_weblink).id,
				:weblink=>{:title=>'Update Weblink by Non Group Admin'}},
			{:user=>users(:staff).id}
		assert_response :redirect
		assert_equal groups(:public_group), assigns(:item)
		assert_nil assigns(:weblink)
		# weblink was not updated
		assert_equal original_title, weblinks(:update_weblink).title
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_weblinks_update_no_user
		original_title = weblinks(:update_weblink).title
		put :update, {:group_id=>groups(:public_group).subpath,
				:id=>weblinks(:update_weblink).id,
				:weblink=>{:title=>'Update Weblink with No User'}},
			{}
		assert_response :redirect
		assert_equal groups(:public_group), assigns(:item)
		assert_nil assigns(:weblink)
		# weblink was not updated
		assert_equal original_title, weblinks(:update_weblink).title
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_weblinks_update_no_params
		original_title = weblinks(:update_weblink).title
		put :update, {:group_id=>groups(:public_group).subpath,
				:id=>weblinks(:update_weblink).id, :weblink=>{}},
			{:user=>users(:login).id}
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal groups(:public_group), assigns(:item)
		assert_equal weblinks(:update_weblink), assigns(:weblink)
		# weblink was not updated
		assert_equal original_title, weblinks(:update_weblink).title
		assert_nil flash[:notice]
		assert_equal "Edit Weblink for #{weblinks(:update_weblink).user.nickname}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			#assert_select 'h1', assigns(:item).display_name
			#assert_select 'h2', "Edit Weblink for #{assigns(:weblink).user.nickname}"
			#assert_select "form[action='#{group_weblink_path(assigns(:item), assigns(:weblink))}']" do
			#	assert_select 'input#weblink_user_id', false,
			#		'Edit form should not contain the user id'
			#	assert_select 'input#weblink_is_admin'
			#	assert_select 'input#weblink_can_add_event'
			#	assert_select 'input#weblink_can_invite'
			#	assert_select 'input#weblink_can_moderate'
			#	assert_select 'input#weblink_can_manage_members'
			#	assert_select 'input#weblink_expires_at'
			#	assert_select 'input#weblink_title'
			#end
		end
	end
	
	end #if false
	#	••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
	
	# DELETE
	def test_weblinks_destroy_with_admin_user
		# create a weblink to be destroyed
		weblink = nil
		assert_difference(Weblink, :count, 1) do
			weblink = Weblink.new({:title=>'Delete Weblink',
				:url=>'http://wayground.ca/weblink/to/delete'})
			weblink.item = groups(:public_group)
			weblink.user = users(:login)
			weblink.save!
		end
		# destroy the weblink (and it's thumbnail)
		assert_difference(Weblink, :count, -1) do
			delete :destroy, {:group_id=>groups(:public_group).subpath,
				:id=>weblink.id}, {:user=>users(:admin).id}
			# TODO: test destroy with staff user
		end
		assert_response :redirect
		assert_equal groups(:public_group), assigns(:item)
		assert flash[:notice]
		assert_redirected_to group_url(assigns(:item))
	end
	def test_weblinks_destroy_with_wrong_user
		assert_difference(Weblink, :count, 0) do
			delete :destroy, {:group_id=>groups(:public_group).subpath,
				:id=>weblinks(:one).id},
				{:user=>users(:plain).id}
		end
		assert_response :redirect
		assert_nil assigns(:item)
		assert_nil assigns(:weblink)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_weblinks_destroy_with_no_user
		assert_difference(Weblink, :count, 0) do
			delete :destroy, {:group_id=>groups(:public_group).subpath,
				:id=>weblinks(:one).id}, {}
		end
		assert_response :redirect
		assert_nil assigns(:item)
		assert_nil assigns(:weblink)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_weblinks_destroy_with_invalid_id
		assert_difference(Weblink, :count, 0) do
			delete :destroy, {:group_id=>groups(:public_group).subpath,
				:id=>'invalid'}, {:user=>users(:admin).id}
		end
		assert_response :missing
		assert_equal groups(:public_group), assigns(:item)
		assert_nil assigns(:weblink)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	def test_weblinks_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {:group_id=>groups(:public_group).subpath},
				{:user=>users(:admin).id}
		end
	end
end
