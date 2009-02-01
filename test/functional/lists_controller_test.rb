require 'test_helper'

class ListsControllerTest < ActionController::TestCase
	fixtures :listitems, :users, :events, :pages, :weblinks

	def setup
		@controller = ListsController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		# map.resources :lists
		assert_routing_for_resources 'lists', [], [], {}, {}
	end
	
	
	# ACTIONS
	
	test "index" do
		assert_efficient_sql do
			get :index, {}, {:user=>users(:login).id}
		end
		assert_equal 'Your Lists', assigns(:page_title)
		assert_equal 1, assigns(:lists).size
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_events_index
			assigns(:lists).each do |list|
				assert_select "li", list.title
			end
		end
	end
	
	test "show" do
#		assert_efficient_sql do
			get :show, {:id=>listitems(:one).title}, {:user=>users(:login).id}
#		end
		assert_equal "Your List: #{listitems(:one).title}", assigns(:page_title)
		assert_equal 2, assigns(:listitems).size
		assert_nil flash[:notice]
		assert_response :success
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_events_index
			assigns(:listitems).each do |listitem|
				assert_select "li#listitem_#{listitem.id}", listitem.item.title
			end
		end
	end
	test "show empty list" do
#		assert_efficient_sql do
			get :show, {:id=>'Non-existent list'}, {:user=>users(:login).id}
#		end
		assert_equal "Your List: Non-existent list", assigns(:page_title)
		assert_equal 0, assigns(:listitems).size
		assert flash[:notice]
		assert_response :success
		assert_template 'show'
	end
	
	test "destroy" do
		conditions = ['listitems.user_id = ? AND listitems.title = ?',
			users(:regular).id, listitems(:destroy_this).title]
		assert Listitem.count(:conditions=>conditions) > 0
		assert_efficient_sql do
			delete :destroy, {:id=>listitems(:destroy_this).title},
				{:user=>users(:regular).id}
		end
		assert_equal 0, Listitem.count(:conditions=>conditions)
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to lists_path
	end
	test "destroy empty list" do
		assert_efficient_sql do
			delete :destroy, {:id=>'non-existent list'}, {:user=>users(:regular).id}
		end
		assert flash[:error]
		assert_response :redirect
		assert_redirected_to lists_path
	end
end
