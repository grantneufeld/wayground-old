class ItemsController < ApplicationController
	before_filter :staff_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	verify :method=>:delete, :only=>[:destroy], :redirect_to=>{:action=>:show}
	
	# site page index (page tree?)
	def index
		@section = 'items'
		if params[:id] and params[:id].to_i > 0
			@item = Item.find(params[:id], :include=>:children)
			@items = @item.children
			@page_title = "Site Index: #{@item.title}"
		elsif !(params[:key].blank?)
			@item = nil
			@items = Item.find_by_key(params[:key])
			@page_title = "Site Index: ‘#{params[:key]}’"
		else
			# find all top-level items
			@item = Item.find_home
			if @item
				conditions = ['(items.parent_id IS NULL OR items.parent_id = ?) AND items.id != ?',
					@item.id, @item.id]
			else
				conditions = ['items.parent_id IS NULL']
			end
			@items = Item.find(:all,
				:conditions=>conditions,
				:order=>'items.title',
				:include=>:children)
			@page_title = "Site Index"
		end
		respond_to do |format|
			# TODO: respond to javascript request to add children to page tree
			#
			#format.js  {
			#	# prerender the child items list so it can be used by the rjs
			#	@child_listitems = ''
			#	@items.each do |item|
			#		@child_listitems += render_to_string(:partial=>'treeitem',
			#			:locals=>{:item=>item})
			#	end
			#	@child_listitems = nil if @child_listitems == ''
			#	render :action=>'index.rjs', :status=>(@err_msg.blank? ? 200 : 500)
			#}
			format.html # index.rhtml
			format.xml  { render :xml => @items.to_xml }
		end
	end
	
	# display an item (page)
	def show
		if params[:id].blank?
			if params[:url].blank?
				@item = Item.find_home
			else
				path = (params[:url].is_a?(Array) ?
					params[:url].join('/') : params[:url].to_s)
				if path.length > 0 and path[0].chr != '/'
					path = "/#{path}"
				end
				@item = Item.find(:first,
					:conditions=>
						['(sitepath = ? OR sitepath = ?)', path, "#{path}/"])
			end
		else
			@item = Item.find(params[:id])
		end
		if @item
			@page_title = @item.title
			@content_for_description = @item.description
			respond_to do |format|
				format.html # show.rhtml
				format.xml  { render :xml => @item.to_xml }
			end
		else
			missing
		end
	end
	
	# form for adding an item
	def new
		@item = Item.new(params[:item])
		@item.user = current_user
		@parent = Item.find(params[:id]) rescue nil
		@item.parent = @parent
		@page_title = 'New Item'
		@section = 'items'
	end
	
	# create a new item
	def create
		self.new
		@item.save!
		flash[:notice] = 'New Item was successfully saved.'
		redirect_to @item.sitepath
	#rescue NoMethodError
	#	self.new
	#	render :action=>:new
	rescue ActiveRecord::RecordInvalid
		#self.new
		@section = 'items'
		render :action=>:new
	rescue
		flash.now[:error] = 'An error occurred while trying to save your new Item.'
		#self.new
		@section = 'items'
		render :action=>:new
	end
	
	# form for editing an item
	def edit
		@item = Item.find(params[:id])
		if current_user.admin? or @item.user == current_user
			@page_title = "Edit ‘#{@item.title}’"
			@section = 'items'
		else
			flash[:error] = "You do not have permission to edit the requested item (‘#{params[:id]}’)."
			redirect_to item_path(@item)
			@item = nil
		end
	rescue ActiveRecord::RecordNotFound
		flash[:warning] = "Could not find a item matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	# update an item
	def update
		self.edit
		if response.redirected_to
			# can’t update - was caught in edit
		else
			@item.editor = current_user
			if params[:item] && params[:item].size > 0 && @item.update_attributes(params[:item])
				flash[:notice] = "Updated information for ‘#{@item.title}’."
				redirect_to item_path(@item)
			else
				# failed to save, back to edit form
				@section = 'items'
				render :action=>:edit
			end
		end
	end
	
	# delete an item
	def destroy
		@item = Item.find(params[:id])
		#if current_user.staff? or @item.user == current_user
			@item.destroy
			flash[:notice] = "The item ‘#{@item.title}’ has been permanently removed."
			redirect_to items_path
		#else
		#	flash[:error] = "You do not have permission to modify the requested item (‘#{params[:id]}’)."
		#	redirect_to item_path(@item)
		#	@item = nil
		#end
	rescue ActiveRecord::RecordNotFound
		flash[:warning] = "Could not find a item matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	# report that the requested url does not exist (missing - 404 error)
	def missing
		@page_title = '404 Missing'
		@path = get_path
		flash.now[:error] = "Requested page not found (‘#{@path}’)."
		render :action=>'missing', :status=>'404 Missing'
	end
	
	# report an error result
	def error
		@page_title = '500 Error'
		@path = get_path
		flash.now[:error] = "An error occurred while attempting to access ‘#{@path}’."
		render :action=>'error', :status=>'500 Error'
	end
	
	
	protected
	
	# determine the request path
	def get_path
		# TODO: need to get the cgi request path if params[:url] is nil
		if params[:url].is_a? Array
			path = params[:url].join '/'
		else
			path = params[:url].to_s
		end
		if path.length > 0 and path[0].chr != '/'
			path = '/' + path
		end
		path
	end
end
