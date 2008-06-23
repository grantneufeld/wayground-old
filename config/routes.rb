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

	map.login '/login', :controller=>'sessions', :action=>'new'
	map.logout '/logout', :controller=>'sessions', :action=>'destroy'
	map.resource :session, :controller=>'sessions'

	map.signup '/signup', :controller=>'users', :action=>'new'
	map.activate '/activate/:activation_code', :controller=>'users',
		:action=>'activate'
	map.profile '/people/:id', :controller=>'users', :action=>'profile'
	map.resources :users, :collection=>{:activate=>:get, :account=>:get}
	
	# special path: the home page
	#map.home '', :controller=>'paths', :action=>'show',
	#	:conditions=>{:method=>:get} #, :url=>nil, :id=>nil
	map.root :controller=>'paths', :action=>'show'
	map.resources :paths
	map.resources :pages
	map.content_switch '/pages/content_type_switch', :controller=>'pages',
		:action=>'content_type_switch', :conditions=>{:method=>:post}
	
	map.private_doc '/private/*filename', :controller=>'documents',
		:action=>'data', :root=>'/private/', :conditions=>{:method=>:get}
	map.resources :documents
	
	# Install the default routes as the lowest priority.
	#map.connect ':controller/:action/:id'
	#map.connect ':controller/:action/:id.:format'
	
	# catch any arbitrary paths not matched above
	map.path '*url', :controller=>'paths', :action=>'show',
		:conditions=>{:method=>:get}
end
