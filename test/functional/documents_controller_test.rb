require File.dirname(__FILE__) + '/../test_helper'

class DocumentsControllerTest < ActionController::TestCase
	fixtures :documents, :sites, :users, :db_files
	

	def setup
		@controller = DocumentsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_resource_routing
		# map.resources :documents
		assert_routing_for_resources 'documents', [], [], {}
	end
	
	def test_routing
		#map.private_doc '/private/:filename', :controller=>'documents',
		#	:action=>'data', :root=>'/private/', :conditions=>{:method=>:get}
		assert_generates('/private/private.doc', {:controller=>'documents',
			:action=>'data', :filename=>['private.doc'], :root=>'/private/'})
		assert_recognizes({:controller=>'documents', :action=>'data',
			:filename=>['private.doc'], :root=>'/private/'},
			'/private/private.doc')
	end
	
	# DATA (get file)
	
	def test_data
		assert_efficient_sql do
			get :data,
				{:filename=>[documents(:text).filename], :root=>'/private/'}
		end
		assert_response :success
		assert assigns(:document)
		assert_nil flash[:notice]
	end
	def test_data_private
		assert_efficient_sql do
			get :data, {:filename=>[documents(:private_text).filename],
				:root=>'/private/'}, {:user=>users(:login).id}
		end
		assert_response :success
		assert assigns(:document)
		assert_nil flash[:notice]
	end
	def test_data_private_admin
		assert_efficient_sql do
			get :data, {:filename=>[documents(:private_text).filename],
				:root=>'/private/'}, {:user=>users(:admin).id}
		end
		assert_response :success
		assert assigns(:document)
		assert_nil flash[:notice]
	end
	def test_data_private_staff
		assert_efficient_sql do
			get :data, {:filename=>[documents(:private_text).filename],
				:root=>'/private/'}, {:user=>users(:staff).id}
		end
		assert_response :success
		assert assigns(:document)
		assert_nil flash[:notice]
	end
	def test_data_private_no_user
		assert_efficient_sql do
			get :data, {:filename=>[documents(:private_text).filename],
				:root=>'/private/'}
		end
		assert_response 404
		assert_nil assigns(:document)
		assert assigns(:url_path)
		assert flash[:error]
		assert_template 'paths/missing'
	end
	def test_data_private_wrong_user
		assert_efficient_sql do
			get :data, {:filename=>[documents(:private_text).filename],
				:root=>'/private/'}, {:user=>users(:regular).id}
		end
		assert_response 404
		assert_nil assigns(:document)
		assert assigns(:url_path)
		assert flash[:error]
		assert_template 'paths/missing'
	end
	def test_data_private_invalid_filename
		assert_efficient_sql do
			get :data, {:filename=>['invalid filename'],
				:root=>'/private/'}, {:user=>users(:login).id}
		end
		assert_response 404
		assert_nil assigns(:document)
		assert assigns(:url_path)
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	# INDEX (LIST)
	
	def test_index
		# FIXME: figure out why `get :index` isn’t passing as efficient sql
#		assert_efficient_sql do
			get :index #, {}, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert assigns(:documents)
		assert_equal 'Documents', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'table' do
				assert_select 'thead'
				assert_select 'tbody' do
					assert_select 'tr', :count=>assigns(:documents).size
				end
			end
		end
	end
	def test_index_search
		# FIXME: figure out why index search isn’t passing as efficient sql
#		assert_efficient_sql do
			get :index, {:key=>'text'} #, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert_equal 2, assigns(:documents).size
		assert_equal 'Documents: ‘text’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'table' do
				assert_select 'thead'
				assert_select 'tbody' do
					assert_select 'tr', :count=>assigns(:documents).size
				end
			end
		end
	end
	
	# SHOW
	
	def test_show
		assert_efficient_sql do
			get :show, {:id=>documents(:text)}
		end
		assert_response :success
		assert assigns(:document)
		assert_equal "Document: ‘#{documents(:text).filename}’",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', documents(:text).fileurl
		end
	end
	# test private
	def test_show_private
#		assert_efficient_sql do
			get :show, {:id=>documents(:private_text)},
				{:user=>users(:login).id}
#		end
		assert_response :success
		assert assigns(:document)
		assert_equal "Document: ‘#{documents(:private_text).filename}’",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', documents(:private_text).fileurl
		end
	end
	# test private admin user
	def test_show_private_admin_user
#		assert_efficient_sql do
			get :show, {:id=>documents(:private_text)},
				{:user=>users(:admin).id}
#		end
		assert_response :success
		assert assigns(:document)
		assert_equal "Document: ‘#{documents(:private_text).filename}’",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', documents(:private_text).fileurl
		end
	end
	# test private admin user
	def test_show_private_staff_user
#		assert_efficient_sql do
			get :show, {:id=>documents(:private_text)},
				{:user=>users(:staff).id}
#		end
		assert_response :success
		assert assigns(:document)
		assert_equal "Document: ‘#{documents(:private_text).filename}’",
			assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', documents(:private_text).fileurl
		end
	end
	# test private incorrect user
	def test_show_private_invalid_user
		assert_efficient_sql do
			get :show, {:id=>documents(:private_text)},
				{:user=>users(:regular).id}
		end
		assert_response :redirect
		assert_nil assigns(:document)
		assert flash[:notice]
		assert_redirected_to documents_path
	end 
	# test private no user
	def test_show_private_no_user
		assert_efficient_sql do
			get :show, {:id=>documents(:private_text)}
		end
		assert_response :redirect
		assert_nil assigns(:document)
		assert flash[:notice]
		assert_redirected_to documents_path
	end 
	# test missing id
	def test_show_no_id
		assert_raise(ActionController::RoutingError) do
			get :show, {}, {:user=>users(:admin).id}
		end
	end
	
	# NEW
	
	def test_new
		get :new, {}, {:user=>users(:login).id}
		assert_response :success
		assert assigns(:document)
		assert assigns(:document).user == users(:login)
		assert_nil flash[:notice]
		assert_equal 'New Document', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{documents_path}]" do
#				assert_select 'select#site_select'
				assert_select 'input[type=file]'
			end
		end
	end
	def test_new_no_user
		get :new
		assert_response :redirect
		assert_nil assigns(:document)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	# CREATE
	def test_create
		assert_difference(DocImage, :count, 2) do
			file_data = fixture_file_upload('/files/upload.jpg','image/jpeg')
			post :create,
				{:document=>{:uploaded_data=>file_data, :site_select=>sites(:arusha).id}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert assigns(:document)
		assert assigns(:document).is_a?(DocImage)
		assert assigns(:document).user == users(:login)
		assert flash[:notice]
		assert_redirected_to document_path(assigns(:document))
		# cleanup - remove uploaded file & thumb(s)
		assigns(:document).destroy
	end
	def test_create_no_params
		assert_difference(Document, :count, 0) do
			post :create, {}, {:user=>users(:login).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert assigns(:document)
		assert assigns(:document).user == users(:login)
		assert_nil flash[:notice]
		assert_equal 'New Document', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: Check for ERRORS LIST
			assert_select "form[action=#{documents_path}]" do
#				assert_select 'select#site_select'
				assert_select 'input[type=file]'
			end
		end
	end
	def test_create_no_user
		assert_difference(DocImage, :count, 0) do
			file_data = fixture_file_upload('/files/upload.jpg','image/jpeg')
			post :create,
				{:document=>{:uploaded_data=>file_data, :site_select=>sites(:arusha).id}}
		end
		assert_response :redirect
		assert_nil assigns(:document)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	# TODO future: add support for editing/updating documents
	## EDIT
	#def test_edit
	#	get :edit, {:id=>documents(:text).id}, {:user=>users(:login).id}
	#	assert_response :success
	#	assert_equal documents(:text), assigns(:document)
	#	assert_nil flash[:notice]
	#	assert_equal "Edit ‘#{documents(:text).filename}’", assigns(:page_title)
	#	# view result
	#	assert_template 'edit'
	#	assert_select 'div#flash:empty'
	#	assert_select 'div#content' do
	#		assert_select "form[action=#{document_path(documents(:text))}]" do
	#			assert_select 'select#site_select'
	#			assert_select 'input#document_filename'
	#		end
	#	end
	#end
	#def test_edit_admin
	#	get :edit, {:id=>documents(:text).id}, {:user=>users(:admin).id}
	#	assert_response :success
	#	assert_equal documents(:text), assigns(:document)
	#	assert_nil flash[:notice]
	#	assert_equal "Edit ‘#{documents(:text).filename}’", assigns(:page_title)
	#	# view result
	#	assert_template 'edit'
	#	assert_select 'div#flash:empty'
	#	assert_select 'div#content' do
	#		assert_select "form[action=#{document_path(documents(:text))}]" do
	#			assert_select 'select#site_select'
	#			assert_select 'input#document_filename'
	#		end
	#	end
	#end
	#def test_edit_invalid_user
	#	get :edit, {:id=>documents(:text).id}, {:user=>users(:staff).id}
	#	assert_response :redirect
	#	assert_nil assigns(:document)
	#	assert flash[:notice]
	#	assert_redirected_to document_path(documents(:text))
	#end
	#def test_edit_no_user
	#	get :edit, {:id=>documents(:text).id}, {}
	#	assert_response :redirect
	#	assert_nil assigns(:document)
	#	assert flash[:warning]
	#	assert_redirected_to login_path
	#end
	#def test_edit_no_id
	#	assert_raise(ActionController::RoutingError) do
	#		get :edit, {}, {:user=>users(:login).id}
	#	end
	#end
	#def test_edit_invalid_id
	#	get :edit, {:id=>'invalid'}, {:user=>users(:login).id}
	#	assert_response :redirect
	#	assert_nil assigns(:document)
	#	assert flash[:notice]
	#	assert_redirected_to documents_path
	#end
	#
	## UPDATE
	#def test_update
	#	content_length = documents(:text).size
	#	put :update, {:id=>documents(:text).id,
	#		:document=>{:site_select=>sites(:one), :filename=>'moved.txt'}},
	#		{:user=>users(:login).id}
	#	assert_response :redirect
	#	assert_equal documents(:text), assigns(:document)
	#	assert_equal 'caldol/moved.txt', assigns(:document).folder_path
	#	assert_equal content_length, assigns(:document).content.size
	#	assert flash[:notice]
	#	assert_redirected_to documents_path(documents(:text))
	#	# reset attributes
	#	assigns(:document).update_attributes!(
	#		{:site_select=>nil, :filename=>'text.txt'})
	#end
	#def test_update_admin
	#	
	#end
	#def test_update_invalid_user
	#	
	#end
	#def test_update_no_user
	#	
	#end
	#def test_update_invalid_params
	#	
	#end
	#def test_update_no_params
	#	
	#end
	
	# DELETE
	def test_destroy
		# upload a file to be destroyed
		doc = nil
		assert_difference(Document, :count, 2) do
			file_data = fixture_file_upload('/files/upload.jpg','image/jpeg')
			doc = DocImage.new({:uploaded_data=>file_data, :site_select=>''})
			doc.user = users(:login)
			doc.save!
		end
		# destroy the file (and it's thumbnail)
		assert_difference(Document, :count, -2) do
			delete :destroy, {:id=>doc.id}, {:user=>users(:login).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to documents_path
	end
	def test_destroy_with_admin_user
		# upload a file to be destroyed
		doc = nil
		assert_difference(Document, :count, 2) do
			file_data = fixture_file_upload('/files/upload.jpg','image/jpeg')
			doc = DocImage.new({:uploaded_data=>file_data, :site_select=>''})
			doc.user = users(:login)
			doc.save!
		end
		# destroy the file (and it's thumbnail)
		assert_difference(Document, :count, -2) do
			delete :destroy, {:id=>doc.id}, {:user=>users(:admin).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to documents_path
	end
	def test_destroy_with_wrong_user
		assert_difference(Document, :count, 0) do
			delete :destroy, {:id=>documents(:text).id},
				{:user=>users(:staff).id}
		end
		assert_response :redirect
		assert_nil assigns(:document)
		assert flash[:notice]
		assert_redirected_to document_path(documents(:text))
	end
	def test_destroy_with_no_user
		assert_difference(Document, :count, 0) do
			delete :destroy, {:id=>documents(:text).id}, {}
		end
		assert_response :redirect
		assert_nil assigns(:document)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_destroy_with_invalid_id
		assert_difference(Document, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:document)
		assert flash[:notice]
		assert_redirected_to documents_path
	end
	def test_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:login).id}
		end
	end
end
