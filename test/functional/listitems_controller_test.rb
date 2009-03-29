require 'test_helper'

class ListitemsControllerTest < ActionController::TestCase
	fixtures :lists, :listitems, :users, :events, :pages, :weblinks

	def setup
		@controller = ListitemsController.new
		@request = ActionController::TestRequest.new
		@response = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	test "resource routing" do
		#map.listitems
		assert_routing_for_resources 'listitems', [], [], {}, {}
	end
	
	
	# ACTIONS
	
	test "create" do
		assert_difference(Listitem, :count, 1) do
			post :create, {:list_id=>lists(:one).id,
				:listitem=>{:item_type=>'Weblink', :item_id=>weblinks(:one).id}},
				{:user=>users(:login).id}
		end
		assert assigns(:listitem).is_a?(Listitem)
		assert_equal weblinks(:one), assigns(:listitem).item
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to({:controller=>'weblinks', :action=>'show', :id=>weblinks(:one)})
		# cleanup
		assigns(:listitem).destroy
	end
	test "create no params" do
		assert_difference(Listitem, :count, 0) do
			post :create, {:list_id=>lists(:one).id, :listitem=>{}}, {:user=>users(:login).id}
		end
		assert assigns(:listitem)
		assert assigns(:listitem).is_a?(Listitem)
		assert flash[:error]
		assert_response :redirect
		assert_redirected_to lists_path
	end
	
	test "destroy" do
		# create a listitem to be destroyed
		listitem = nil
		assert_difference(Listitem, :count, 1) do
			listitem = lists(:one).listitems.new
			listitem.item = pages(:three)
			listitem.save!
		end
		# destroy the listitem
		assert_difference(Listitem, :count, -1) do
			@request.accept = "text/html"
			delete :destroy, {:id=>listitem.id}, {:user=>users(:login).id}
		end
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to lists_path
	end
	test "destroy with admin" do
		# create a listitem to be destroyed
		listitem = nil
		assert_difference(Listitem, :count, 1) do
			listitem = lists(:one).listitems.new
			listitem.item = pages(:three)
			listitem.save!
		end
		# destroy the listitem
		assert_difference(Listitem, :count, -1) do
			@request.accept = "text/html"
			delete :destroy, {:id=>listitem.id}, {:user=>users(:admin).id}
		end
		assert flash[:notice]
		assert_response :redirect
		assert_redirected_to lists_path
	end
	test "destroy with wrong user" do
		assert_difference(Listitem, :count, 0) do
			delete :destroy, {:id=>listitems(:one).id}, {:user=>users(:another).id}
		end
		assert flash[:error]
		assert_response :redirect
		assert_redirected_to account_users_path
	end
	test "destroy with no user" do
		assert_difference(Listitem, :count, 0) do
			delete :destroy, {:id=>listitems(:one).id}, {}
		end
		assert flash[:warning]
		assert_response :redirect
		assert_redirected_to login_path
	end
	test "destroy with invalid id" do
		assert_difference(Listitem, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:admin).id}
		end
		assert flash[:error]
		assert_response :missing
		assert_template 'paths/missing'
	end
	test "destroy with no id" do
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:admin).id}
		end
	end
	test "destroy with javascript" do
		# create a listitem to be destroyed
		listitem = nil
		assert_difference(Listitem, :count, 1) do
			listitem = lists(:one).listitems.new
			listitem.item = pages(:three)
			listitem.save!
		end
		# destroy the listitem
		assert_difference(Listitem, :count, -1) do
			@request.accept = "text/javascript"
			delete :destroy, {:id=>listitem.id}, {:user=>users(:login).id}
		end
		assert flash[:notice]
		assert_response :success
		assert_template 'destroy'
	end
	test "destroy via javascript with wrong user" do
		assert_difference(Listitem, :count, 0) do
			@request.accept = "text/javascript"
			delete :destroy, {:id=>listitems(:one).id}, {:user=>users(:another).id}
		end
		assert flash[:error]
		assert_response :success
		assert_template 'destroy'
	end
end
