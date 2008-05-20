require File.dirname(__FILE__) + '/../test_helper'

class ItemsControllerTest < ActionController::TestCase
	fixtures :items, :users

	def setup
		@controller = ItemsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_resource_routing
		# map.resources :items
		assert_routing_for_resources 'items', [], [], {}
	end
	
	def test_routing
		#map.home '', :controller=>'items', :action=>'show', :url=>nil, :id=>nil
		assert_generates('/', {:controller=>'items', :action=>'show'})
		assert_recognizes({:controller=>'items', :action=>'show'}, '/')
		#assert_equal '/', home_url
		#assert_equal '/', home_path
		
		#map.page '*url', :controller=>'items', :action=>'show',
		#	:conditions=>{:method=>:get}
		assert_generates('/custom/url', {:controller=>'items', :action=>'show',
			:url=>['custom','url']})
		assert_generates('/custom/url', {:controller=>'items', :action=>'show',
			:url=>'custom/url'})
		assert_recognizes({:controller=>'items', :action=>'show',
			:url=>['custom','url']}, '/custom/url')
	end
	
	# INDEX (LIST)

	def test_index
		# FIXME: figure out why `get :index` isn’t passing as efficient sql
#		assert_efficient_sql do
			get :index #, {}, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert assigns(:items)
		assert_equal 'Site Index', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index
			#assert_select 'table' do
			#	assert_select 'thead'
			#	assert_select 'tbody' do
			#		assert_select 'tr', :count=>assigns(:items).size
			#	end
			#end
		end
	end
	def test_index_search
		assert_efficient_sql do
			get :index, {:key=>'page'} #, {:user=>users(:admin).id}
		end
		assert_response :success
		assert_equal 3, assigns(:items).size
		assert_equal 'Site Index: ‘page’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index_search
			#assert_select 'table' do
			#	assert_select 'thead'
			#	assert_select 'tbody' do
			#		assert_select 'tr', :count=>assigns(:items).size
			#	end
			#end
		end
	end
	def test_index_parent
		assert_efficient_sql do
			get :index, {:id=>items(:two).id}
		end
		assert_response :success
		assert_equal items(:two), assigns(:item)
		assert_equal 1, assigns(:items).size
		assert_equal "Site Index: #{items(:two).title}", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index_parent
			#assert_select 'table' do
			#	assert_select 'thead'
			#	assert_select 'tbody' do
			#		assert_select 'tr', :count=>assigns(:items).size
			#	end
			#end
		end
	end

	# SHOW

	def test_show
		assert_efficient_sql do
			get :show, {:id=>items(:two)}
		end
		assert_response :success
		assert assigns(:item)
		assert_equal items(:two).title, assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', items(:two).title
		end
	end
	# TODO future: support private items
	## test private
	#def test_show_private
	#	assert_efficient_sql do
	#		get :show, {:id=>items(:private_text)},
	#			{:user=>users(:login).id}
	#	end
	#	assert_response :success
	#	assert assigns(:item)
	#	assert_equal items(:private_text).title, assigns(:page_title)
	#	assert_nil flash[:notice]
	#	# view result
	#	assert_template 'show'
	#	assert_select 'div#flash:empty'
	#	assert_select 'div#content' do
	#		assert_select 'h1', items(:private_text).title
	#	end
	#end
	## test private admin user
	#def test_show_private_admin_user
	#	assert_efficient_sql do
	#		get :show, {:id=>items(:private_text)},
	#			{:user=>users(:admin).id}
	#	end
	#	assert_response :success
	#	assert assigns(:item)
	#	assert_equal items(:private_text).title, assigns(:page_title)
	#	assert_nil flash[:notice]
	#	# view result
	#	assert_template 'show'
	#	assert_select 'div#flash:empty'
	#	assert_select 'div#content' do
	#		assert_select 'h1', items(:private_text).title
	#	end
	#end
	## test private incorrect user
	#def test_show_private_invalid_user
	#	assert_efficient_sql do
	#		get :show, {:id=>items(:private_text)},
	#			{:user=>users(:staff).id}
	#	end
	#	assert_response :redirect
	#	assert_nil assigns(:item)
	#	assert flash[:notice]
	#	assert_redirected_to items_path
	#end 
	## test private no user
	#def test_show_private_no_user
	#	assert_efficient_sql do
	#		get :show, {:id=>items(:private_text)}
	#	end
	#	assert_response :redirect
	#	assert_nil assigns(:item)
	#	assert flash[:notice]
	#	assert_redirected_to items_path
	#end 
	# test missing id - gets home page
	def test_show_no_id
		assert_efficient_sql do
			get :show, {}, {:user=>users(:admin).id}
		end
		assert_response :success
		assert assigns(:item)
		assert_equal items(:one).title, assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', items(:one).title
		end
	end

	# NEW

	def test_new
		get :new, {}, {:user=>users(:staff).id}
		assert_response :success
		assert assigns(:item)
		assert assigns(:item).user == users(:staff)
		assert_nil flash[:notice]
		assert_equal 'New Item', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{items_path}]" do
				assert_select 'input#item_subpath'
				assert_select 'input#item_title'
				assert_select 'input#item_description'
				assert_select 'textarea#item_content'
				assert_select 'select#item_content_type'
				assert_select 'input#item_keywords'
			end
		end
	end
	def test_new_user_not_staff
		get :new, {}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_new_no_user
		get :new
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to login_path
	end

	# CREATE
	def test_create
		assert_difference(Item, :count, 1) do
			post :create, {:item=>{
				:subpath=>'test_create', :title=>'Create Item',
				:description=>'This item was created from test_create.',
				:content=>'<h1>Create Item</h1><p>Created by test_create.</p>',
				:content_type=>'text/html', :keywords=>'test, create, new'}},
				{:user=>users(:staff).id}
		end
		assert_response :redirect
		assert assigns(:item)
		assert assigns(:item).is_a?(Item)
		assert assigns(:item).user == users(:staff)
		assert flash[:notice]
		assert_redirected_to assigns(:item).sitepath
		# cleanup
		assigns(:item).destroy
	end
	def test_create_no_params
		assert_difference(Item, :count, 0) do
			post :create, {}, {:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert assigns(:item)
		assert assigns(:item).user == users(:staff)
		assert_nil flash[:notice]
		assert_equal 'New Item', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: Check for ERRORS LIST
			assert_select "form[action=#{items_path}]" do
				assert_select 'input#item_subpath'
				assert_select 'input#item_title'
				assert_select 'input#item_description'
				assert_select 'textarea#item_content'
				assert_select 'select#item_content_type'
				assert_select 'input#item_keywords'
			end
		end
	end
	def test_create_user_without_access
		assert_difference(Item, :count, 0) do
			post :create, {:item=>{
				:subpath=>'test_create', :title=>'Create Item',
				:description=>'This item was created from test_create.',
				:content=>'<h1>Create Item</h1><p>Created by test_create.</p>',
				:content_type=>'text/html', :keywords=>'test, create, new'}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_create_no_user
		assert_difference(Item, :count, 0) do
			post :create, {:item=>{
				:subpath=>'test_create', :title=>'Create Item',
				:description=>'This item was created from test_create.',
				:content=>'<h1>Create Item</h1><p>Created by test_create.</p>',
				:content_type=>'text/html', :keywords=>'test, create, new'}},
				{}
		end
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to login_path
	end

	# EDIT
	def test_edit
		get :edit, {:id=>items(:three).id}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal items(:three), assigns(:item)
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{items(:three).title}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{item_path(items(:three))}]" do
				assert_select 'input#item_subpath'
				assert_select 'input#item_title'
				assert_select 'input#item_description'
				assert_select 'textarea#item_content'
				assert_select 'select#item_content_type'
				assert_select 'input#item_keywords'
			end
		end
	end
	def test_edit_admin
		get :edit, {:id=>items(:two).id}, {:user=>users(:admin).id}
		assert_response :success
		assert_equal items(:two), assigns(:item)
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{items(:two).title}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{item_path(items(:two))}]" do
				assert_select 'input#item_subpath'
				assert_select 'input#item_title'
				assert_select 'input#item_description'
				assert_select 'textarea#item_content'
				assert_select 'select#item_content_type'
				assert_select 'input#item_keywords'
			end
		end
	end
	def test_edit_invalid_user
		get :edit, {:id=>items(:two).id}, {:user=>users(:staff).id}
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:error]
		assert_redirected_to item_path(items(:two))
	end
	def test_edit_no_user
		get :edit, {:id=>items(:two).id}, {}
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_edit_no_id
		assert_raise(ActionController::RoutingError) do
			get :edit, {}, {:user=>users(:staff).id}
		end
	end
	def test_edit_invalid_id
		get :edit, {:id=>'invalid'}, {:user=>users(:staff).id}
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to items_path
	end
	
	## UPDATE
	def test_update
		put :update, {:id=>items(:update_this).id,
			:item=>{:subpath=>'test_update', :title=>'test_update',
				:description=>'test_update', :content=>'test_update',
				:keywords=>'test_update'}},
			{:user=>users(:staff).id}
		assert_response :redirect
		assert_equal items(:update_this), assigns(:item)
		assert_equal users(:staff), assigns(:item).editor
		assert_equal 'test_update', assigns(:item).subpath
		assert_equal '/test_update', assigns(:item).sitepath
		assert_equal 'test_update', assigns(:item).title
		assert_equal 'test_update', assigns(:item).description
		assert_equal 'test_update', assigns(:item).content
		assert_equal 'test_update', assigns(:item).keywords
		assert flash[:notice]
		assert_redirected_to item_path(items(:update_this))
	end
	def test_update_admin
		put :update, {:id=>items(:update_this).id,
			:item=>{:subpath=>'test_update_admin', :title=>'test_update_admin',
				:description=>'test_update_admin',
				:content=>'test_update_admin', :keywords=>'test_update_admin'}},
			{:user=>users(:admin).id}
		assert_response :redirect
		assert_equal items(:update_this), assigns(:item)
		assert_equal users(:staff), assigns(:item).user
		assert_equal users(:admin), assigns(:item).editor
		assert_equal 'test_update_admin', assigns(:item).subpath
		assert_equal '/test_update_admin', assigns(:item).sitepath
		assert_equal 'test_update_admin', assigns(:item).title
		assert_equal 'test_update_admin', assigns(:item).description
		assert_equal 'test_update_admin', assigns(:item).content
		assert_equal 'test_update_admin', assigns(:item).keywords
		assert flash[:notice]
		assert_redirected_to item_path(items(:update_this))
	end
	def test_update_non_staff_or_admin_user
		original_title = items(:update_this).title
		put :update, {:id=>items(:update_this).id,
			:item=>{:subpath=>'test_update_not_staff',
				:title=>'test_update_not_staff',
				:description=>'test_update_not_staff',
				:content=>'test_update_not_staff',
				:keywords=>'test_update_not_staff'}},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:item)
		# item was not updated
		assert_equal original_title, items(:update_this).title
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_update_no_user
		original_title = items(:update_this).title
		put :update, {:id=>items(:update_this).id,
			:item=>{:subpath=>'test_update_no_user',
				:title=>'test_update_no_user',
				:description=>'test_update_no_user',
				:content=>'test_update_no_user',
				:keywords=>'test_update_no_user'}},
			{}
		assert_response :redirect
		assert_nil assigns(:item)
		# item was not updated
		assert_equal original_title, items(:update_this).title
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_update_invalid_params
		original_title = items(:update_this).title
		put :update, {:id=>items(:update_this).id,
			:item=>{:subpath=>'not valid subpath!',
				:title=>'test_update_invalid',
				:description=>'test_update_invalid',
				:content=>'test_update_invalid',
				:keywords=>'test_update_invalid'}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal items(:update_this), assigns(:item)
		# item was not updated
		assert_equal original_title, items(:update_this).title
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{items(:update_this).title}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{item_path(items(:update_this))}]" do
				assert_select 'input#item_subpath'
				assert_select 'input#item_title'
				assert_select 'input#item_description'
				assert_select 'textarea#item_content'
				assert_select 'select#item_content_type'
				assert_select 'input#item_keywords'
			end
		end
	end
	def test_update_no_params
		original_title = items(:update_this).title
		put :update, {:id=>items(:update_this).id, :item=>{}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal items(:update_this), assigns(:item)
		# item was not updated
		assert_equal original_title, items(:update_this).title
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{items(:update_this).title}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{item_path(items(:update_this))}]" do
				assert_select 'input#item_subpath'
				assert_select 'input#item_title'
				assert_select 'input#item_description'
				assert_select 'textarea#item_content'
				assert_select 'select#item_content_type'
				assert_select 'input#item_keywords'
			end
		end
	end

	# DELETE
	def test_destroy
		# create an item to be destroyed
		item = nil
		assert_difference(Item, :count, 1) do
			item = Item.new({:subpath=>'to_delete', :title=>'Delete This'})
			item.user = users(:login)
			item.save!
		end
		# non-staff users can’t destroy items
		assert_difference(Item, :count, 0) do
			delete :destroy, {:id=>item.id}, {:user=>users(:login).id}
		end
		assert_response :redirect
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_destroy_with_admin_user
		# create an item to be destroyed
		item = nil
		assert_difference(Item, :count, 1) do
			item = Item.new({:subpath=>'to_delete', :title=>'Delete This'})
			item.user = users(:login)
			item.save!
		end
		# destroy the item (and it's thumbnail)
		assert_difference(Item, :count, -1) do
			delete :destroy, {:id=>item.id}, {:user=>users(:admin).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to items_path
	end
	def test_destroy_with_staff_user
		# create an item to be destroyed
		item = nil
		assert_difference(Item, :count, 1) do
			item = Item.new({:subpath=>'to_delete', :title=>'Delete This'})
			item.user = users(:login)
			item.save!
		end
		# destroy the item (and it's thumbnail)
		assert_difference(Item, :count, -1) do
			delete :destroy, {:id=>item.id}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to items_path
	end
	def test_destroy_with_wrong_user
		assert_difference(Item, :count, 0) do
			delete :destroy, {:id=>items(:three).id},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_destroy_with_no_user
		assert_difference(Item, :count, 0) do
			delete :destroy, {:id=>items(:two).id}, {}
		end
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_destroy_with_invalid_id
		assert_difference(Item, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert_nil assigns(:item)
		assert flash[:warning]
		assert_redirected_to items_path
	end
	def test_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:staff).id}
		end
	end
end
