require 'test_helper'

class EventsControllerTest < ActionController::TestCase
	fixtures :events, :users, :schedules, :rsvps, :groups, :locations, :tags

	def setup
		@controller = EventsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	def test_events_resource_routing
		#map.resources :events do |events|
		#	events.resources :schedules do |schedules|
		#		schedules.resources :rsvps
		#	end
		#end
		assert_routing_for_resources 'events', [], [], {}, {}
	end
	
	# INDEX (LIST)
	def test_events_index
#		assert_efficient_sql do
			get :index #, {}, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert_equal 4, assigns(:events).size
		assert_equal 'Events', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_events_index
			assigns(:events).each do |p|
				assert_select "li#event_#{p.id}"
			end
		end
	end
	def test_events_index_search
#		assert_efficient_sql do
			get :index, {:key=>'keyword'} #, {:user=>users(:admin).id}
#		end
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert_equal 1, assigns(:events).size
		assert_equal 'Events: ‘keyword’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_events_index_search
			assigns(:events).each do |p|
				assert_select "li#event_#{p.id}"
			end
		end
	end


	# SHOW
	def test_events_show
		# ignore range error on sql explain
		# OPTIMIZE: I played around with index possibilities, but couldn’t find a way to get the lookup of confirmed_schedules to not produce a range message on the SQL EXPLAIN call. Any suggestions?
		#assert_raise_message Test::Unit::AssertionFailedError,
		#/Pessimistic.*Signature Load.*\| range \|/m do
			assert_efficient_sql(:diagnostic=>nil) do
				get :show, {:id=>events(:one).id}
			end
		#end
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert_equal events(:one), assigns(:event)
		assert_equal [schedules(:one)], assigns(:event).schedules
		assert_equal("Event: #{events(:one).title}", assigns(:page_title))
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', events(:one).title
		end
	end
	def test_events_show_invalid_id
		#assert_efficient_sql do
			get :show, {:id=>'0'}
		#end
		assert_response :missing
		assert_nil assigns(:event)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# NEW
	def test_events_new
		get :new, {}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert assigns(:event)
		assert_nil flash[:notice]
		assert_equal 'New Event', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{events_path}]" do
				assert_select 'input#event_subpath'
				assert_select 'input#event_title'
				assert_select 'input#event_description'
				assert_select 'textarea#event_content'
#				assert_select 'input#event_content_type'
			end
		end
	end
	def test_events_new_user_not_staff
		get :new, {}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_events_new_no_user
		get :new
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# CREATE
	def test_events_create
		assert_difference(Event, :count, 1) do
			post :create, {:event=>{:subpath=>'test_create',
				:title=>'Controller Creation Test',
				:description=>'Created event.',
				:content=>'This should be a valid event.',
				:content_type=>'text/plain'},
				:schedule=>{:start_at=>Time.now.to_s, :end_at=>1.hour.from_now.to_s,
					:info=>'schedule for controller creation test'}},
				{:user=>users(:staff).id}
		end
		assert_response :redirect
		assert assigns(:event)
		assert assigns(:event).is_a?(Event)
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:event)})
		# cleanup
		assigns(:event).destroy
	end
	def test_events_create_no_params
		assert_difference(Event, :count, 0) do
			post :create, {}, {:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert assigns(:event)
		assert_validation_errors_on(assigns(:event), ['subpath', 'title', 'schedules'])
		assert_nil flash[:notice]
		assert_equal 'New Event', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{events_path}]"
		end
	end
	def test_events_create_bad_params
		assert_difference(Event, :count, 0) do
			post :create, {:event=>{:subpath=>'bad subpath',
				:title=>'Test Bad Params',
				:content=>'Test of event creation with bad params.',
				:content_type=>'application/invalid'},
				:schedule=>{:start_at=>Time.now.to_s, :end_at=>1.hour.from_now.to_s,
					:info=>'schedule for controller creation test'}},
				{:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert assigns(:event)
		assert_validation_errors_on(assigns(:event), ['subpath', 'content_type'])
		assert_nil flash[:notice]
		assert_equal 'New Event', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{events_path}]"
		end
	end
	def test_events_create_user_without_access
		assert_difference(Event, :count, 0) do
			post :create, {:event=>{:subpath=>'no-access',
				:title=>'Test No Access',
				:content=>'Test of event creation with invalid access.'}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:event)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_events_create_no_user
		assert_difference(Event, :count, 0) do
			post :create, {:event=>{:subpath=>'no-user', :title=>'Test No User',
				:content=>'Test of event creation with no user.'}},
				{}
		end
		assert_response :redirect
		assert_nil assigns(:event)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# EDIT
	def test_events_edit
		get :edit, {:id=>events(:one).id}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert_equal events(:one), assigns(:event)
		assert_nil flash[:notice]
		assert_equal "Edit Event: #{events(:one).title}", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{events_path()}/#{events(:one).subpath}']" do
				assert_select 'input#event_subpath'
				assert_select 'input#event_title'
				assert_select 'input#event_description'
				assert_select 'textarea#event_content'
#				assert_select 'input#event_content_type'
			end
		end
	end
	def test_events_edit_invalid_user
		get :edit, {:id=>events(:one).id}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:event)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_events_edit_no_user
		get :edit, {:id=>events(:one).id}, {}
		assert_response :redirect
		assert_nil assigns(:event)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_events_edit_no_id
		assert_raise(ActionController::RoutingError) do
			get :edit, {}, {:user=>users(:staff).id}
		end
	end
	def test_events_edit_invalid_id
		get :edit, {:id=>'invalid'}, {:user=>users(:staff).id}
		assert_response :missing
		assert_nil assigns(:event)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# UPDATE
	def test_events_update
		put :update,
			{:id=>events(:update_event).id,
				:event=>{
					:subpath=>'updated',
					:title=>'updated',
					:description=>'updated',
					:content=>'updated',
					:content_type=>'text/plain'
				}},
			{:user=>users(:staff).id}
		assert_response :redirect
		assert_equal events(:update_event), assigns(:event)
		# check that all of the fields are updated as expected
		assert_equal 'updated', assigns(:event).subpath
		assert_equal 'updated', assigns(:event).title
		assert_equal 'updated', assigns(:event).description
		assert_equal 'updated', assigns(:event).content
		assert_equal 'text/plain', assigns(:event).content_type
		#
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:event)})
	end
	def test_events_update_non_staff_or_admin_user
		original_name = events(:update_event).title
		put :update, {:id=>events(:update_event).id,
			:event=>{:title=>'Update Event by Non Staff'}},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:event)
		# event was not updated
		assert_equal original_name, events(:update_event).title
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_events_update_no_user
		original_name = events(:update_event).title
		put :update, {:id=>events(:update_event).id,
			:event=>{:title=>'Update Event with No User'}},
			{}
		assert_response :redirect
		assert_nil assigns(:event)
		# event was not updated
		assert_equal original_name, events(:update_event).title
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_events_update_invalid_params
		original_title = events(:update_event).title
		put :update, {:id=>events(:update_event).id,
			:event=>{:subpath=>'invalid subpath'}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert_equal events(:update_event), assigns(:event)
		assert_validation_errors_on(assigns(:event), ['subpath'])
		# event was not updated
		assert_equal original_title, events(:update_event).title
		assert_nil flash[:notice]
		assert_equal "Edit Event: #{events(:update_event).title}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{events_path}/#{events(:update_event).subpath}']"
		end
	end
	def test_events_update_no_params
		original_title = events(:update_event).title
		put :update, {:id=>events(:update_event).id, :event=>{}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal 'events', assigns(:section)
		assert_equal events(:update_event), assigns(:event)
		# event was not updated
		assert_equal original_title, events(:update_event).title
		assert_nil flash[:notice]
		assert_equal "Edit Event: #{events(:update_event).title}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{events_path}/#{events(:update_event).subpath}']"
		end
	end
	def test_events_update_invalid_id
		put :update,
			{:id=>0,
				:event=>{
					:subpath=>'updated',
					:title=>'updated',
					:description=>'updated',
					:content=>'updated',
					:content_type=>'text/plain'
				}},
			{:user=>users(:staff).id}
		assert_response :missing
		assert_nil assigns(:event)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# DELETE
	def test_events_destroy_with_admin_user
		# create a event to be destroyed
		event = nil
		assert_difference(Event, :count, 1) do
			event = Event.new({:title=>'Delete Event',
				:subpath=>'delete-event', :description=>'Delete this event.'})
			event.user = users(:admin)
			event.save!
		end
		# destroy the event
		assert_difference(Event, :count, -1) do
			delete :destroy, {:id=>event.id}, {:user=>users(:admin).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to events_path
	end
	def test_events_destroy_with_staff_user
		# create a event to be destroyed
		event = nil
		assert_difference(Event, :count, 1) do
			event = Event.new({:title=>'Delete Event',
				:subpath=>'delete-event', :description=>'Delete this event.'})
			event.user = users(:admin)
			event.save!
		end
		# destroy the event
		assert_difference(Event, :count, -1) do
			delete :destroy, {:id=>event.id}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to events_path
	end
	def test_events_destroy_with_wrong_user
		assert_difference(Event, :count, 0) do
			delete :destroy, {:id=>events(:one).id},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:event)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_events_destroy_with_no_user
		assert_difference(Event, :count, 0) do
			delete :destroy, {:id=>events(:one).id}, {}
		end
		assert_response :redirect
		assert_nil assigns(:event)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_events_destroy_with_invalid_id
		assert_difference(Event, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:staff).id}
		end
		assert_response :missing
		assert_nil assigns(:event)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	def test_events_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:staff).id}
		end
	end
end
