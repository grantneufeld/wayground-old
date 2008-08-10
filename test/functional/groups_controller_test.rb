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
	def test_index
		assert_efficient_sql do
			get :index #, {}, {:user=>users(:admin).id}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal 3, assigns(:groups).size
		assert_equal 'Groups', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index
			assigns(:groups).each do |g|
				assert_select "li#group_#{g.id}"
			end
		end
	end
	def test_index_search
		assert_efficient_sql do
			get :index, {:key=>'keyword'} #, {:user=>users(:admin).id}
		end
		assert_response :success
		assert_equal 'groups', assigns(:section)
		assert_equal 2, assigns(:groups).size
		assert_equal 'Groups: ‘keyword’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_index_search
			assigns(:groups).each do |g|
				assert_select "li#group_#{g.id}"
			end
		end
	end


	# TODO: SHOW

	# TODO: NEW

	# TODO: CREATE
	# TODO: EDIT
	# TODO: UPDATE
	# TODO: DELETE
end
