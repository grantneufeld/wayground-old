require File.dirname(__FILE__) + '/../test_helper'

class PagesControllerTest < ActionController::TestCase
	fixtures :pages, :users, :paths

	def setup
		@controller = PagesController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_resource_routing
		# map.resources :pages
		assert_routing_for_resources 'pages', [], [], {}
	end
	
	def test_routing
		# map.content_switch '/pages/content_type_switch', :controller=>'pages',
		# 	:action=>'content_type_switch', :conditions=>{:method=>:post}
		assert_generates("/pages/content_type_switch",
			{:controller=>"pages", :action=>"content_type_switch"})
		assert_recognizes(
			{:controller=>"pages", :action=>"content_type_switch"},
			{:path=>"/pages/content_type_switch", :method=>:post})
	end
	
	# INDEX (LIST)

	def test_index
		# FIXME: figure out why `get :index` isn’t passing as efficient sql
#		assert_efficient_sql do
			get :index #, {}, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert assigns(:pages)
		assert_equal 'Site Index', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index
			assigns(:pages).each do |p|
				assert_select "li#page_#{p.id}"
			end
		end
	end
	def test_index_search
#		assert_efficient_sql do
			get :index, {:key=>'keyword'} #, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert_equal 2, assigns(:pages).size
		assert_equal 'Site Index: ‘keyword’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index_search
			#assert_select 'ul' do
			#	assert_select 'li', :count=>assigns(:pages).size
			#end
		end
	end
	def test_index_parent
		assert_efficient_sql do
			get :index, {:id=>pages(:two).id}
		end
		assert_response :success
		assert_equal pages(:two), assigns(:page)
		assert_equal 1, assigns(:pages).size
		assert_equal "Site Index: #{pages(:two).title}", assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index_parent
			#assert_select 'ul' do
			#	assert_select 'li', :count=>assigns(:pages).size
			#end
		end
	end

	# SHOW

	def test_show
		assert_efficient_sql do
			get :show, {:id=>pages(:two)}
		end
		assert_response :success
		assert assigns(:page)
		assert_equal pages(:two).title, assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', pages(:two).title
		end
	end
	
	# TODO future: support private pages
	## test private
	#def test_show_private
	#	assert_efficient_sql do
	#		get :show, {:id=>pages(:private_text)},
	#			{:user=>users(:login).id}
	#	end
	#	assert_response :success
	#	assert assigns(:page)
	#	assert_equal pages(:private_text).title, assigns(:page_title)
	#	assert_nil flash[:notice]
	#	# view result
	#	assert_template 'show'
	#	assert_select 'div#flash:empty'
	#	assert_select 'div#content' do
	#		assert_select 'h1', pages(:private_text).title
	#	end
	#end
	## test private admin user
	#def test_show_private_admin_user
	#	assert_efficient_sql do
	#		get :show, {:id=>pages(:private_text)},
	#			{:user=>users(:admin).id}
	#	end
	#	assert_response :success
	#	assert assigns(:page)
	#	assert_equal pages(:private_text).title, assigns(:page_title)
	#	assert_nil flash[:notice]
	#	# view result
	#	assert_template 'show'
	#	assert_select 'div#flash:empty'
	#	assert_select 'div#content' do
	#		assert_select 'h1', pages(:private_text).title
	#	end
	#end
	## test private incorrect user
	#def test_show_private_invalid_user
	#	assert_efficient_sql do
	#		get :show, {:id=>pages(:private_text)},
	#			{:user=>users(:staff).id}
	#	end
	#	assert_response :redirect
	#	assert_nil assigns(:page)
	#	assert flash[:notice]
	#	assert_redirected_to pages_path
	#end 
	## test private no user
	#def test_show_private_no_user
	#	assert_efficient_sql do
	#		get :show, {:id=>pages(:private_text)}
	#	end
	#	assert_response :redirect
	#	assert_nil assigns(:page)
	#	assert flash[:notice]
	#	assert_redirected_to pages_path
	#end 
	# test missing id - can’t show without an id
	def test_show_no_id
		assert_raise(ActionController::RoutingError) do
			get :show, {}, {:user=>users(:admin).id}
		end
	end

	# NEW

	def test_new
		get :new, {}, {:user=>users(:staff).id}
		assert_response :success
		assert assigns(:page)
		assert assigns(:page).user == users(:staff)
		assert_nil flash[:notice]
		assert_equal 'New Page', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{pages_path}]" do
				assert_select 'input#page_subpath'
				assert_select 'input#page_title'
				assert_select 'input#page_description'
#				assert_select 'textarea#page_content'
#				assert_select 'select#page_content_type'
				assert_select 'input#page_keywords'
			end
		end
	end
	def test_new_user_not_staff
		get :new, {}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_new_no_user
		get :new
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to login_path
	end

	# CREATE
	def test_create
		assert_difference(Page, :count, 1) do
			post :create, {
				:page=>{
					:subpath=>'test_create', :title=>'Create Page',
					:description=>'This page was created from test_create.',
					:keywords=>'test, create, new'
				},
				:chunks=>{
					'0_content_1'=>{
						:type=>'raw', :part=>'content',
						:position=>'1',
						:flavour=>'', :old_content_type=>'text/html',
						:content=>'<h1>Create Page</h1><p>Created by test_create.</p>',
						:content_type=>'text/html'
					}
				}
			},
			{:user=>users(:staff).id}
		end
		assert_response :redirect
		assert assigns(:page)
		assert assigns(:page).is_a?(Page)
		assert assigns(:page).user == users(:staff)
		assert flash[:notice]
		assert_redirected_to assigns(:page).sitepath
		# cleanup
		assigns(:page).destroy
	end
	def test_create_no_params
		assert_difference(Page, :count, 0) do
			post :create, {}, {:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert assigns(:page)
		assert_validation_errors_on(assigns(:page), ['title','subpath'])
		assert assigns(:page).user == users(:staff)
		assert_nil flash[:notice]
		assert_equal 'New Page', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{pages_path}]" do
				assert_select 'input#page_subpath'
				assert_select 'input#page_title'
				assert_select 'input#page_description'
#				assert_select 'textarea#page_content'
#				assert_select 'select#page_content_type'
				assert_select 'input#page_keywords'
			end
		end
	end
	def test_create_user_without_access
		assert_difference(Page, :count, 0) do
			post :create, {:page=>{
				:subpath=>'test_create', :title=>'Create Page',
				:description=>'This page was created from test_create.',
				:content=>'<h1>Create Page</h1><p>Created by test_create.</p>',
				:content_type=>'text/html', :keywords=>'test, create, new'}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_create_no_user
		assert_difference(Page, :count, 0) do
			post :create, {:page=>{
				:subpath=>'test_create', :title=>'Create Page',
				:description=>'This page was created from test_create.',
				:content=>'<h1>Create Page</h1><p>Created by test_create.</p>',
				:content_type=>'text/html', :keywords=>'test, create, new'}},
				{}
		end
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to login_path
	end

	# EDIT
	def test_edit
		get :edit, {:id=>pages(:three).id}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal pages(:three), assigns(:page)
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{pages(:three).title}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{page_path(pages(:three))}]" do
				assert_select 'input#page_subpath'
				assert_select 'input#page_title'
				assert_select 'input#page_description'
#				assert_select 'textarea#page_content'
#				assert_select 'select#page_content_type'
				assert_select 'input#page_keywords'
			end
		end
	end
	def test_edit_admin
		get :edit, {:id=>pages(:two).id}, {:user=>users(:admin).id}
		assert_response :success
		assert_equal pages(:two), assigns(:page)
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{pages(:two).title}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{page_path(pages(:two))}]" do
				assert_select 'input#page_subpath'
				assert_select 'input#page_title'
				assert_select 'input#page_description'
#				assert_select 'textarea#page_content'
#				assert_select 'select#page_content_type'
				assert_select 'input#page_keywords'
			end
		end
	end
	def test_edit_invalid_user
		get :edit, {:id=>pages(:two).id}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_edit_no_user
		get :edit, {:id=>pages(:two).id}, {}
		assert_response :redirect
		assert_nil assigns(:page)
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
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to pages_path
	end
	
	# UPDATE
	def test_update
		put :update, {:id=>pages(:update_this).id,
			:page=>{:subpath=>'test_update', :title=>'test_update',
				:description=>'test_update', :keywords=>'test_update'},
			:chunks=>{'0_content_1'=>{:type=>'raw', :part=>'content', :position=>'1',
				:flavour=>'', :old_content_type=>'text/html',
				:content=>'test_update', :content_type=>'text/plain'}}},
			{:user=>users(:staff).id}
		assert_response :redirect
		assert_equal pages(:update_this), assigns(:page)
		assert_equal users(:staff), assigns(:page).editor
		assert_equal 'test_update', assigns(:page).subpath
		assert_equal '/test_update', assigns(:page).sitepath
		assert_equal 'test_update', assigns(:page).title
		assert_equal 'test_update', assigns(:page).description
		assert_equal 'test_update', assigns(:page).content
		assert_equal 'test_update', assigns(:page).keywords
		assert flash[:notice]
		assert_redirected_to page_path(pages(:update_this))
	end
	def test_update_admin
		put :update, {:id=>pages(:update_this).id,
			:page=>{:subpath=>'test_update_admin', :title=>'test_update_admin',
				:description=>'test_update_admin',
				:content=>'test_update_admin', :keywords=>'test_update_admin'}},
			{:user=>users(:admin).id}
		assert_response :redirect
		assert_equal pages(:update_this), assigns(:page)
		assert_equal users(:staff), assigns(:page).user
		assert_equal users(:admin), assigns(:page).editor
		assert_equal 'test_update_admin', assigns(:page).subpath
		assert_equal '/test_update_admin', assigns(:page).sitepath
		assert_equal 'test_update_admin', assigns(:page).title
		assert_equal 'test_update_admin', assigns(:page).description
		assert_equal 'test_update_admin', assigns(:page).content
		assert_equal 'test_update_admin', assigns(:page).keywords
		assert flash[:notice]
		assert_redirected_to page_path(pages(:update_this))
	end
	def test_update_non_staff_or_admin_user
		original_title = pages(:update_this).title
		put :update, {:id=>pages(:update_this).id,
			:page=>{:subpath=>'test_update_not_staff',
				:title=>'test_update_not_staff',
				:description=>'test_update_not_staff',
				:content=>'test_update_not_staff',
				:keywords=>'test_update_not_staff'}},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:page)
		# page was not updated
		assert_equal original_title, pages(:update_this).title
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_update_no_user
		original_title = pages(:update_this).title
		put :update, {:id=>pages(:update_this).id,
			:page=>{:subpath=>'test_update_no_user',
				:title=>'test_update_no_user',
				:description=>'test_update_no_user',
				:content=>'test_update_no_user',
				:keywords=>'test_update_no_user'}},
			{}
		assert_response :redirect
		assert_nil assigns(:page)
		# page was not updated
		assert_equal original_title, pages(:update_this).title
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_update_invalid_params
		original_title = pages(:update_this).title
		put :update, {:id=>pages(:update_this).id,
			:page=>{:subpath=>'not valid subpath!',
				:title=>'test_update_invalid',
				:description=>'test_update_invalid',
				:content=>'test_update_invalid',
				:keywords=>'test_update_invalid'}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal pages(:update_this), assigns(:page)
		# page was not updated
		assert_equal original_title, pages(:update_this).title
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{pages(:update_this).title}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{page_path(pages(:update_this))}]" do
				assert_select 'input#page_subpath'
				assert_select 'input#page_title'
				assert_select 'input#page_description'
#				assert_select 'textarea#page_content'
#				assert_select 'select#page_content_type'
				assert_select 'input#page_keywords'
			end
		end
	end
	def test_update_no_params
		original_title = pages(:update_this).title
		put :update, {:id=>pages(:update_this).id, :page=>{}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal pages(:update_this), assigns(:page)
		# page was not updated
		assert_equal original_title, pages(:update_this).title
		assert_nil flash[:notice]
		assert_equal "Edit ‘#{pages(:update_this).title}’", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{page_path(pages(:update_this))}]" do
				assert_select 'input#page_subpath'
				assert_select 'input#page_title'
				assert_select 'input#page_description'
#				assert_select 'textarea#page_content'
#				assert_select 'select#page_content_type'
				assert_select 'input#page_keywords'
			end
		end
	end

	# DELETE
	def test_destroy
		# create a page to be destroyed
		page = nil
		assert_difference(Page, :count, 1) do
			page = Page.new({:subpath=>'to_delete', :title=>'Delete This'})
			page.user = users(:login)
			page.save!
		end
		# non-staff users can’t destroy pages
		assert_difference(Page, :count, 0) do
			delete :destroy, {:id=>page.id}, {:user=>users(:login).id}
		end
		assert_response :redirect
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_destroy_with_admin_user
		# create a page to be destroyed
		page = nil
		assert_difference(Page, :count, 1) do
			page = Page.new({:subpath=>'to_delete', :title=>'Delete This'})
			page.user = users(:login)
			page.save!
		end
		# destroy the page (and it's thumbnail)
		assert_difference(Page, :count, -1) do
			delete :destroy, {:id=>page.id}, {:user=>users(:admin).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to pages_path
	end
	def test_destroy_with_staff_user
		# create a page to be destroyed
		page = nil
		assert_difference(Page, :count, 1) do
			page = Page.new({:subpath=>'to_delete', :title=>'Delete This'})
			page.user = users(:login)
			page.save!
		end
		# destroy the page (and it's thumbnail)
		assert_difference(Page, :count, -1) do
			delete :destroy, {:id=>page.id}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to pages_path
	end
	def test_destroy_with_wrong_user
		assert_difference(Page, :count, 0) do
			delete :destroy, {:id=>pages(:three).id},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_destroy_with_no_user
		assert_difference(Page, :count, 0) do
			delete :destroy, {:id=>pages(:two).id}, {}
		end
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_destroy_with_invalid_id
		assert_difference(Page, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to pages_path
	end
	def test_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:staff).id}
		end
	end
	
	# dynamic content format change
	# TODO: test rjs update of content field based on changing content_type
end
