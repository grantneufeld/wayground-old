require 'test_helper'

class PathsControllerTest < ActionController::TestCase
	fixtures :pages, :users, :paths

	def setup
		@controller = PathsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	# ROUTING
	
	def test_resource_routing
		# map.resources :paths
		assert_routing_for_resources 'paths', [], [], {}
	end
	
	def test_routing
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
	# TODO test paths controller index action

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
			# TODO: test html content for test_index
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
		assert_equal 5, assigns(:paths).size
		assert_equal 'Site Paths: ‘t’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index_search
			#assert_select 'table' do
			#	assert_select 'thead'
			#	assert_select 'tbody' do
			#		assert_select 'tr', :count=>assigns(:paths).size
			#	end
			#end
		end
	end
	
	# SHOW

	def test_path_show_url
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
	def test_path_show_home
		assert_efficient_sql do
			get :show, {}
		end
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
	def test_path_show_redirect
		assert_efficient_sql do
			get :show, {:url=>['redirect_me']}
		end
		assert_response :redirect
		assert assigns(:path)
		assert_nil assigns(:item)
		assert_nil flash[:notice]
		assert_redirected_to paths(:redirect_me).redirect
	end
	
	# TODO test path controller actions: new create edit update destroy
	
end
