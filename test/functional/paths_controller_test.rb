require 'test_helper'

class PathsControllerTest < ActionController::TestCase
	fixtures :pages, :users, :paths

	def setup
		@controller = PathsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_paths_resource_routing
		# map.resources :paths
		assert_routing_for_resources 'paths', [], [], {}
	end
	
	def test_paths_routing
		#map.root :controller=>'paths', :action=>'show'
		assert_generates('/', {:controller=>'paths', :action=>'show'})
		assert_recognizes({:controller=>'paths', :action=>'show'}, '/')
		#assert_equal '/', root_url
		#assert_equal '/', root_path
		
		#map.path '*url', :controller=>'paths', :action=>'show',
		#	:conditions=>{:method=>:get}
		assert_generates('/custom/url', {:controller=>'paths', :action=>'show',
			:url=>['custom','url']})
		# FIXME: generation of route strings is url-encoding slashes when it shouldn’t be
		#assert_generates('/custom/url', {:controller=>'paths', :action=>'show',
		#	:url=>'custom/url'})
		assert_recognizes({:controller=>'paths', :action=>'show',
			:url=>['custom','url']}, '/custom/url')
	end
	
	# INDEX (LIST)

	def test_paths_index
		# FIXME: figure out why `get :index` isn’t passing as efficient sql
		#assert_efficient_sql do
			get :index #, {}, {:user=>users(:admin).id}
		#end
		assert_response :success
		assert assigns(:paths)
		assert_equal 'Site Paths', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_paths_index
			#assert_select 'table' do
			#	assert_select 'thead'
			#	assert_select 'tbody' do
			#		assert_select 'tr', :count=>assigns(:paths).size
			#	end
			#end
		end
	end
	def test_paths_index_search
		# OPTIMIZE: doing sql LIKE searches is inefficient
		#assert_efficient_sql do
			get :index, {:key=>'t'} #, {:user=>users(:admin).id}
		#end
		assert_response :success
		assert_equal Path.find_by_key('t').size, assigns(:paths).size
		assert_equal 'Site Paths: ‘t’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_paths_index_search
			#assert_select 'table' do
			#	assert_select 'thead'
			#	assert_select 'tbody' do
			#		assert_select 'tr', :count=>assigns(:paths).size
			#	end
			#end
		end
	end
	
	# SHOW
	def test_paths_show_info
		assert_efficient_sql do
			get :show, {:id=>paths(:redirect_me).id.to_s}
		end
		assert_response :success
		assert assigns(:path)
		assert_equal("Path #{paths(:redirect_me).sitepath}",
			assigns(:page_title))
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' #do
		#	assert_select 'td', paths(:three).sitepath
		#end
	end
	def test_paths_show_url
		assert_efficient_sql do
			get :show, {:url=>['two','three']}
		end
		assert_response :success
		assert assigns(:path)
		assert assigns(:item)
		assert_equal paths(:three).item.title, assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', paths(:three).item.title
		end
	end
	def test_paths_show_home
		#assert_efficient_sql do
			get :show, {}
		#end
		assert_response :success
		assert assigns(:path)
		assert assigns(:item)
		assert_equal paths(:one).item.title, assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', paths(:one).item.title
		end
	end
	def test_paths_show_redirect
		assert_efficient_sql do
			get :show, {:url=>['redirect_me']}
		end
		assert_response :redirect
		assert assigns(:path)
		assert_nil assigns(:item)
		assert_nil flash[:notice]
		assert_redirected_to paths(:redirect_me).redirect
	end
	
	# NEW
	def test_paths_new
		get :new, {}, {:user=>users(:staff).id}
		assert_response :success
		assert assigns(:path)
		assert_nil flash[:notice]
		assert_equal 'New Path', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{paths_path}]" do
				assert_select 'input#path_sitepath'
				assert_select 'input#path_redirect'
			end
		end
	end
	def test_paths_new_user_not_staff
		get :new, {}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_paths_new_no_user
		get :new
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to login_path
	end

	# CREATE
	def test_paths_create
		assert_difference(Path, :count, 1) do
			post :create, {:path=>{:sitepath=>'/test/create',
				:redirect=>'http://wayground.ca/test/created'}},
				{:user=>users(:staff).id}
		end
		assert_response :redirect
		assert assigns(:path)
		assert assigns(:path).is_a?(Path)
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:path)})
		# cleanup
		assigns(:path).destroy
	end
	def test_paths_create_no_params
		assert_difference(Path, :count, 0) do
			post :create, {}, {:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert assigns(:path)
		assert_validation_errors_on(assigns(:path), ['sitepath', 'redirect'])
		assert_nil flash[:notice]
		assert_equal 'New Path', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{paths_path}]" do
				assert_select 'input#path_sitepath'
				assert_select 'input#path_redirect'
			end
		end
	end
	def test_paths_create_bad_params
		assert_difference(Path, :count, 0) do
			post :create, {:path=>{:sitepath=>'bad sitepath',
				:redirect=>'http://wayground.ca/test/created'}},
				{:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert assigns(:path)
		assert_validation_errors_on(assigns(:path), ['sitepath'])
		assert_nil flash[:notice]
		assert_equal 'New Path', assigns(:page_title)
		# view result
		#debugger
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{paths_path}]" do
				assert_select 'input#path_sitepath'
				assert_select 'input#path_redirect'
			end
		end
	end
	def test_paths_create_user_without_access
		assert_difference(Path, :count, 0) do
			post :create, {:path=>{:sitepath=>'/test/create/no_access',
				:redirect=>'http://wayground.ca/test/created/no_access'}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:path)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_paths_create_no_user
		assert_difference(Path, :count, 0) do
			post :create, {:path=>{:sitepath=>'/test/create/no_user',
				:redirect=>'http://wayground.ca/test/created/no_user'}},
				{}
		end
		assert_response :redirect
		assert_nil assigns(:path)
		assert flash[:warning]
		assert_redirected_to login_path
	end

	# EDIT
	def test_paths_edit
		get :edit, {:id=>paths(:three).id}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal paths(:three), assigns(:path)
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{paths(:three).sitepath}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{paths_path()}/#{paths(:three).id}']" do
				assert_select 'input#path_sitepath'
				assert_select 'input#path_redirect'
			end
		end
	end
	def test_paths_edit_admin
		get :edit, {:id=>paths(:two).id}, {:user=>users(:admin).id}
		assert_response :success
		assert_equal paths(:two), assigns(:path)
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{paths(:two).sitepath}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{paths_path()}/#{paths(:two).id}']" do
				assert_select 'input#path_sitepath'
				assert_select 'input#path_redirect'
			end
		end
	end
	def test_paths_edit_invalid_user
		get :edit, {:id=>paths(:two).id}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:path)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_paths_edit_no_user
		get :edit, {:id=>paths(:two).id}, {}
		assert_response :redirect
		assert_nil assigns(:path)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_paths_edit_no_id
		assert_raise(ActionController::RoutingError) do
			get :edit, {}, {:user=>users(:staff).id}
		end
	end
	def test_paths_edit_invalid_id
		get :edit, {:id=>'invalid'}, {:user=>users(:staff).id}
		assert_response :redirect
		assert_nil assigns(:path)
		assert flash[:warning]
		assert_redirected_to paths_path
	end
	
	# UPDATE
	def test_paths_update
		put :update, {:id=>paths(:update_redirect).id,
			:path=>{:sitepath=>'/test_paths_update',
				:redirect=>'http://wayground.ca/test_paths_update'}},
			{:user=>users(:staff).id}
		assert_response :redirect
		assert_equal paths(:update_redirect), assigns(:path)
		assert_equal '/test_paths_update', assigns(:path).sitepath
		assert_equal 'http://wayground.ca/test_paths_update',
			assigns(:path).redirect
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:path)})
	end
	def test_paths_update_admin
		put :update, {:id=>paths(:update_redirect).id,
			:path=>{:sitepath=>'/test_paths_update_admin',
				:redirect=>'http://wayground.ca/test_paths_update_admin'}},
			{:user=>users(:admin).id}
		assert_response :redirect
		assert_equal paths(:update_redirect), assigns(:path)
		assert_equal '/test_paths_update_admin', assigns(:path).sitepath
		assert_equal 'http://wayground.ca/test_paths_update_admin',
			assigns(:path).redirect
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:path)})
	end
	def test_paths_update_non_staff_or_admin_user
		original_sitepath = paths(:update_redirect).sitepath
		put :update, {:id=>paths(:update_redirect).id,
			:path=>{:sitepath=>'/test_paths_update_not_staff',
				:redirect=>'http://wayground.ca/test_paths_update_not_staff'}},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:path)
		# path was not updated
		assert_equal original_sitepath, paths(:update_redirect).sitepath
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_paths_update_no_user
		original_sitepath = paths(:update_redirect).sitepath
		put :update, {:id=>paths(:update_redirect).id,
			:path=>{:sitepath=>'/test_paths_update_no_user',
				:redirect=>'http://wayground.ca/test_paths_update_no_user'}},
			{}
		assert_response :redirect
		assert_nil assigns(:path)
		# path was not updated
		assert_equal original_sitepath, paths(:update_redirect).sitepath
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_paths_update_invalid_params
		original_sitepath = paths(:update_redirect).sitepath
		put :update, {:id=>paths(:update_redirect).id,
			:path=>{:sitepath=>'not valid sitepath!',
				:redirect=>'not valid redirect!'}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal paths(:update_redirect), assigns(:path)
		assert_validation_errors_on(assigns(:path), ['sitepath', 'redirect'])
		# path was not updated
		assert_equal original_sitepath, paths(:update_redirect).sitepath
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{paths(:update_redirect).sitepath}’",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{paths_path}/#{paths(:update_redirect).id}']" do
				assert_select 'input#path_sitepath'
				assert_select 'input#path_redirect'
			end
		end
	end
	def test_paths_update_no_params
		original_sitepath = paths(:update_redirect).sitepath
		put :update, {:id=>paths(:update_redirect).id, :path=>{}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal paths(:update_redirect), assigns(:path)
		# path was not updated
		assert_equal original_sitepath, paths(:update_redirect).sitepath
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{paths(:update_redirect).sitepath}’",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{paths_path}/#{paths(:update_redirect).id}']" do
				assert_select 'input#path_sitepath'
				assert_select 'input#path_redirect'
			end
		end
	end

	# DELETE
	def test_paths_destroy_with_admin_user
		# create a path to be destroyed
		path = nil
		assert_difference(Path, :count, 1) do
			path = Path.new({:sitepath=>'/to_delete',
				:redirect=>'http://wayground.ca/to_delete'})
			path.save!
		end
		# destroy the path (and it's thumbnail)
		assert_difference(Path, :count, -1) do
			delete :destroy, {:id=>path.id}, {:user=>users(:admin).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to paths_path
	end
	def test_paths_destroy_with_staff_user
		# create a path to be destroyed
		path = nil
		assert_difference(Path, :count, 1) do
			path = Path.new({:sitepath=>'/to_delete',
				:redirect=>'http://wayground.ca/to_delete'})
			path.save!
		end
		# destroy the path (and it's thumbnail)
		assert_difference(Path, :count, -1) do
			delete :destroy, {:id=>path.id}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to paths_path
	end
	def test_paths_destroy_with_wrong_user
		assert_difference(Path, :count, 0) do
			delete :destroy, {:id=>paths(:three).id},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:path)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_paths_destroy_with_no_user
		assert_difference(Path, :count, 0) do
			delete :destroy, {:id=>paths(:two).id}, {}
		end
		assert_response :redirect
		assert_nil assigns(:path)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_paths_destroy_with_invalid_id
		assert_difference(Path, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert_nil assigns(:path)
		assert flash[:warning]
		assert_redirected_to paths_path
	end
	def test_paths_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:staff).id}
		end
	end
end
