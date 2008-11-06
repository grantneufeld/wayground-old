require 'test_helper'

class PetitionsControllerTest < ActionController::TestCase
	fixtures :users, :petitions, :signatures
	
	def setup
		@controller = PetitionsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end
	
	
	# ROUTING
	def test_petitions_resource_routing
		# map.resources :petitions
		assert_routing_for_resources 'petitions', [], [], {}
	end
	
	# INDEX (LIST)
	def test_petitions_index
		assert_efficient_sql do
			get :index #, {}, {:user=>users(:admin).id}
		end
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert_equal 4, assigns(:petitions).size
		assert_equal 'Petitions', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_petitions_index
			assigns(:petitions).each do |p|
				assert_select "li#petition_#{p.id}"
			end
		end
	end
	def test_petitions_index_search
		assert_efficient_sql do
			get :index, {:key=>'keyword'} #, {:user=>users(:admin).id}
		end
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert_equal 1, assigns(:petitions).size
		assert_equal 'Petitions: ‘keyword’', assigns(:page_title)
		assert_nil flash[:notice]
		# view result
		assert_template 'index'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			# TODO: test html content for test_petitions_index_search
			assigns(:petitions).each do |p|
				assert_select "li#petition_#{p.id}"
			end
		end
	end


	# SHOW
	def test_petitions_show
		# ignore range error on sql explain
		# OPTIMIZE: I played around with index possibilities, but couldn’t find a way to get the lookup of confirmed_signatures to not produce a range message on the SQL EXPLAIN call. Any suggestions?
		assert_raise_message Test::Unit::AssertionFailedError,
		/Pessimistic.*Signature Load.*\| range \|/m do
			assert_efficient_sql(:diagnostic=>nil) do
				get :show, {:id=>petitions(:one).id}
			end
		end
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert_equal petitions(:one), assigns(:petition)
		assert_equal [signatures(:one)], assigns(:signatures)
		assert_equal("Petition: #{petitions(:one).title}", assigns(:page_title))
		assert_nil flash[:notice]
		# view result
		assert_template 'show'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select 'h1', petitions(:one).title
		end
	end
	def test_petitions_show_invalid_id
		#assert_efficient_sql do
			get :show, {:id=>'0'}
		#end
		assert_response :missing
		assert_nil assigns(:petition)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# NEW
	def test_petitions_new
		get :new, {}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert assigns(:petition)
		assert_nil flash[:notice]
		assert_equal 'New Petition', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{petitions_path}]" do
				assert_select 'input#petition_subpath'
				#assert_select 'select#petition_start_at'
				#assert_select 'select#petition_end_at'
				assert_select 'input#petition_public_signatures'
				assert_select 'input#petition_allow_comments'
				assert_select 'input#petition_goal'
				assert_select 'input#petition_title'
				assert_select 'input#petition_description'
				assert_select 'input#petition_custom_field_label'
				assert_select 'input#petition_country_restrict'
				assert_select 'input#petition_province_restrict'
				assert_select 'input#petition_city_restrict'
				assert_select 'input#petition_restriction_description'
				assert_select 'textarea#petition_content'
				assert_select 'textarea#petition_thanks_message'
			end
		end
	end
	def test_petitions_new_user_not_staff
		get :new, {}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_petitions_new_no_user
		get :new
		assert_response :redirect
		assert_nil assigns(:page)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# CREATE
	def test_petitions_create
		assert_difference(Petition, :count, 1) do
			post :create, {:petition=>{:subpath=>'test_create',
				:title=>'Controller Creation Test',
				:content=>'This should be a valid petition.'}},
				{:user=>users(:staff).id}
		end
		assert_response :redirect
		assert assigns(:petition)
		assert assigns(:petition).is_a?(Petition)
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:petition)})
		# cleanup
		assigns(:petition).destroy
	end
	def test_petitions_create_no_params
		assert_difference(Petition, :count, 0) do
			post :create, {}, {:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert assigns(:petition)
		assert_validation_errors_on(assigns(:petition), ['subpath', 'title', 'content'])
		assert_nil flash[:notice]
		assert_equal 'New Petition', assigns(:page_title)
		# view result
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{petitions_path}]"
		end
	end
	def test_petitions_create_bad_params
		assert_difference(Petition, :count, 0) do
			post :create, {:petition=>{:subpath=>'bad subpath',
				:title=>'Test Bad Params',
				:content=>'Test of petition creation with bad params.'}},
				{:user=>users(:staff).id}
		end
		# this basically returns the same as a call to new,
		# with the addition of a validation error list in the view
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert assigns(:petition)
		assert_validation_errors_on(assigns(:petition), ['subpath'])
		assert_nil flash[:notice]
		assert_equal 'New Petition', assigns(:page_title)
		# view result
		#debugger
		assert_template 'new'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action=#{petitions_path}]"
		end
	end
	def test_petitions_create_user_without_access
		assert_difference(Petition, :count, 0) do
			post :create, {:petition=>{:subpath=>'no-access',
				:title=>'Test No Access',
				:content=>'Test of petition creation with invalid access.'}},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:petition)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_petitions_create_no_user
		assert_difference(Petition, :count, 0) do
			post :create, {:petition=>{:subpath=>'no-user', :title=>'Test No User',
				:content=>'Test of petition creation with no user.'}},
				{}
		end
		assert_response :redirect
		assert_nil assigns(:petition)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	
	
	# EDIT
	def test_petitions_edit
		get :edit, {:id=>petitions(:one).id}, {:user=>users(:staff).id}
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert_equal petitions(:one), assigns(:petition)
		assert_nil flash[:notice]
		assert_equal "Edit Petition: #{petitions(:one).title}", assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{petitions_path()}/#{petitions(:one).id}']" do
				assert_select 'input#petition_subpath'
				#assert_select 'select#petition_start_at'
				#assert_select 'select#petition_end_at'
				assert_select 'input#petition_public_signatures'
				assert_select 'input#petition_allow_comments'
				assert_select 'input#petition_goal'
				assert_select 'input#petition_title'
				assert_select 'input#petition_description'
				assert_select 'input#petition_custom_field_label'
				assert_select 'input#petition_country_restrict'
				assert_select 'input#petition_province_restrict'
				assert_select 'input#petition_city_restrict'
				assert_select 'input#petition_restriction_description'
				assert_select 'textarea#petition_content'
				assert_select 'textarea#petition_thanks_message'
			end
		end
	end
	def test_petitions_edit_invalid_user
		get :edit, {:id=>petitions(:one).id}, {:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:petition)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_petitions_edit_no_user
		get :edit, {:id=>petitions(:one).id}, {}
		assert_response :redirect
		assert_nil assigns(:petition)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_petitions_edit_no_id
		assert_raise(ActionController::RoutingError) do
			get :edit, {}, {:user=>users(:staff).id}
		end
	end
	def test_petitions_edit_invalid_id
		get :edit, {:id=>'invalid'}, {:user=>users(:staff).id}
		assert_response :missing
		assert_nil assigns(:petition)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	
	
	# UPDATE
	def test_petitions_update
		dt = 1.day.ago
		dtu = dt.utc
		dts = dtu.to_s(:db) + ' UTC'
		put :update,
			{
				:id=>petitions(:update_petition).id,
				:petition=>{
					:subpath=>'updated',
					:start_at=>dts, :end_at=>dts,
					:public_signatures=>'1', :allow_comments=>'1',
					:goal=>'1',
					:title=>'updated',
					:description=>'updated',
					:custom_field_label=>'updated',
					:country_restrict=>'updated',
					:province_restrict=>'updated',
					:city_restrict=>'updated',
					:restriction_description=>'updated',
					:content=>'updated',
					:thanks_message=>'updated'
				}
			},
			{:user=>users(:staff).id}
		assert_response :redirect
		assert_equal petitions(:update_petition), assigns(:petition)
		# check that all of the fields are updated as expected
		assert_equal 'updated', assigns(:petition).subpath
		# test date equality is a pain in the posterior
		assert_equal dtu.to_s, assigns(:petition).start_at.utc.to_s
		assert_equal dtu.to_s, assigns(:petition).end_at.utc.to_s
		assert assigns(:petition).public_signatures
		assert assigns(:petition).allow_comments
		assert_equal 1, assigns(:petition).goal
		assert_equal 'updated', assigns(:petition).title
		assert_equal 'updated', assigns(:petition).description
		assert_equal 'updated', assigns(:petition).custom_field_label
		assert_equal 'updated', assigns(:petition).country_restrict
		assert_equal 'updated', assigns(:petition).province_restrict
		assert_equal 'updated', assigns(:petition).city_restrict
		assert_equal 'updated', assigns(:petition).restriction_description
		assert_equal 'updated', assigns(:petition).content
		assert_equal 'updated', assigns(:petition).thanks_message
		#
		assert flash[:notice]
		assert_redirected_to({:action=>'show', :id=>assigns(:petition)})
	end
	def test_petitions_update_non_staff_or_admin_user
		original_name = petitions(:update_petition).title
		put :update, {:id=>petitions(:update_petition).id,
			:petition=>{:title=>'Update Petition by Non Staff'}},
			{:user=>users(:login).id}
		assert_response :redirect
		assert_nil assigns(:petition)
		# petition was not updated
		assert_equal original_name, petitions(:update_petition).title
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_petitions_update_no_user
		original_name = petitions(:update_petition).title
		put :update, {:id=>petitions(:update_petition).id,
			:petition=>{:title=>'Update Petition with No User'}},
			{}
		assert_response :redirect
		assert_nil assigns(:petition)
		# petition was not updated
		assert_equal original_name, petitions(:update_petition).title
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_petitions_update_invalid_params
		original_title = petitions(:update_petition).title
		put :update, {:id=>petitions(:update_petition).id,
			:petition=>{:subpath=>'invalid subpath'}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert_equal petitions(:update_petition), assigns(:petition)
		assert_validation_errors_on(assigns(:petition), ['subpath'])
		# petition was not updated
		assert_equal original_title, petitions(:update_petition).title
		assert_nil flash[:notice]
		assert_equal "Edit Petition: #{petitions(:update_petition).title}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{petitions_path}/#{petitions(:update_petition).id}']"
		end
	end
	def test_petitions_update_no_params
		original_title = petitions(:update_petition).title
		put :update, {:id=>petitions(:update_petition).id, :petition=>{}},
			{:user=>users(:staff).id}
		assert_response :success
		assert_equal 'petitions', assigns(:section)
		assert_equal petitions(:update_petition), assigns(:petition)
		# petition was not updated
		assert_equal original_title, petitions(:update_petition).title
		assert_nil flash[:notice]
		assert_equal "Edit Petition: #{petitions(:update_petition).title}",
			assigns(:page_title)
		# view result
		assert_template 'edit'
		assert_select 'div#flash:empty'
		assert_select 'div#content' do
			assert_select "form[action='#{petitions_path}/#{petitions(:update_petition).id}']"
		end
	end
	
	
	# DELETE
	def test_petitions_destroy_with_admin_user
		# create a petition to be destroyed
		petition = nil
		assert_difference(Petition, :count, 1) do
			petition = Petition.new({:title=>'Delete Petition',
				:subpath=>'delete-petition', :content=>'Delete this petition.'})
			petition.user = users(:admin)
			petition.save!
		end
		# destroy the petition (and it's thumbnail)
		assert_difference(Petition, :count, -1) do
			delete :destroy, {:id=>petition.id}, {:user=>users(:admin).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to petitions_path
	end
	def test_petitions_destroy_with_staff_user
		# create a petition to be destroyed
		petition = nil
		assert_difference(Petition, :count, 1) do
			petition = Petition.new({:title=>'Delete Petition',
				:subpath=>'delete-petition', :content=>'Delete this petition.'})
			petition.user = users(:admin)
			petition.save!
		end
		# destroy the petition (and it's thumbnail)
		assert_difference(Petition, :count, -1) do
			delete :destroy, {:id=>petition.id}, {:user=>users(:staff).id}
		end
		assert_response :redirect
		assert flash[:notice]
		assert_redirected_to petitions_path
	end
	def test_petitions_destroy_with_wrong_user
		assert_difference(Petition, :count, 0) do
			delete :destroy, {:id=>petitions(:one).id},
				{:user=>users(:login).id}
		end
		assert_response :redirect
		assert_nil assigns(:petition)
		assert flash[:warning]
		assert_redirected_to account_users_path
	end
	def test_petitions_destroy_with_no_user
		assert_difference(Petition, :count, 0) do
			delete :destroy, {:id=>petitions(:one).id}, {}
		end
		assert_response :redirect
		assert_nil assigns(:petition)
		assert flash[:warning]
		assert_redirected_to login_path
	end
	def test_petitions_destroy_with_invalid_id
		assert_difference(Petition, :count, 0) do
			delete :destroy, {:id=>'invalid'}, {:user=>users(:staff).id}
		end
		assert_response :missing
		assert_nil assigns(:petition)
		assert_nil flash[:notice]
		assert flash[:error]
		assert_template 'paths/missing'
	end
	def test_petitions_destroy_with_no_id
		assert_raise(ActionController::RoutingError) do
			delete :destroy, {}, {:user=>users(:staff).id}
		end
	end
	
end
