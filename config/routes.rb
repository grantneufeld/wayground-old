ActionController::Routing::Routes.draw do |map|
	# Sample of regular route:
	#   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
	# Keep in mind you can assign values other than :controller and :action

	# Sample of named route:
	#   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
	# This route can be invoked with purchase_url(:id => product.id)

	# Sample resource route (maps HTTP verbs to controller actions automatically):
	#   map.resources :products

	# Sample resource route with options:
	#   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

	# Sample resource route with sub-resources:
	#   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

	# Sample resource route with more complex sub-resources
	#   map.resources :products do |products|
	#     products.resources :comments
	#     products.resources :sales, :collection => { :recent => :get }
	#   end

	# Sample resource route within a namespace:
	#   map.namespace :admin do |admin|
	#     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
	#     admin.resources :products
	#   end

	# You can have the root of your site routed with map.root -- just remember to delete public/index.html.
	# map.root :controller => "welcome"

	# See how all your routes lay out with "rake routes"

	# SESSION
	map.login '/login', :controller=>'sessions', :action=>'new'
	map.logout '/logout', :controller=>'sessions', :action=>'destroy',
		:conditions=>{:method=>:delete}
	# TODO: map a get route for /logout that has a logout form with method=delete
	map.resource :session, :controller=>'sessions'
	# USER
	map.signup '/signup', :controller=>'users', :action=>'new'
	map.activate '/activate/:activation_code/:encrypt_code', :controller=>'users',
		:action=>'activate'
	map.profile '/people/:id', :controller=>'users', :action=>'profile'
	map.resources :users, :collection=>{:activate=>:get, :account=>:get} do |users|
		users.resources :email_addresses
	end
	map.resources :email_addresses
	
	# PAGES
	# special path: the home page
	#map.home '', :controller=>'paths', :action=>'show',
	#	:conditions=>{:method=>:get} #, :url=>nil, :id=>nil
	map.root :controller=>'paths', :action=>'show'
	map.resources :paths
	map.content_switch '/pages/content_type_switch', :controller=>'pages',
		:action=>'content_type_switch', :conditions=>{:method=>:post}
	map.new_page_chunk '/pages/new_chunk', :controller=>'pages',
		:action=>'new_chunk' #, :conditions=>{:method=>:post}
	map.resources :pages
	
	# DOCUMENTS / FILES
	map.private_doc '/private/*filename', :controller=>'documents',
		:action=>'data', :root=>'/private/', :conditions=>{:method=>:get}
	map.resources :documents
	
	# CONTACT MANAGEMENT
	map.resources(:groups, :member=>{:groups=>:get, :subgroup=>:get, :createsub=>:post}) do |groups|
		groups.resources :memberships, :collection=>{:bulk=>:get, :bulkprocess=>:post}
		groups.resources :emails, :controller=>:email_messages
	end
	map.resources :locations
	#map.resources :memberships
	
	# MESSAGING
	map.resources :email_messages do |email_messages|
		email_messages.resources :attachments
		email_messages.resources :recipients
	end
	map.resources :phone_messages

	# EVENTS
	map.resources :events do |events|
		events.resources :schedules do |schedules|
			schedules.resources :rsvps
		end
	end
	
	# META
	map.resources :lists
	map.resources :listitems
	map.resources :notes
	map.resources :sites
	map.resources :tags
	
	# DEMOCRACY
	map.resources :weblinks
	map.resources :petitions do |petitions|
		petitions.resources :signatures, :member=>{:confirm=>:get}
	end
	
	# Install the default routes as the lowest priority.
	# Note: These default routes make all actions in every controller accessible via GET requests. You should
	# consider removing the them or commenting them out if you're using named routes and resources.
	#map.connect ':controller/:action/:id'
	#map.connect ':controller/:action/:id.:format'
	
	# catch any arbitrary paths not matched above
	map.path '*url', :controller=>'paths', :action=>'show',
		:conditions=>{:method=>:get}
end
