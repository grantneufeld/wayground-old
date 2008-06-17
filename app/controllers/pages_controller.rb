class PagesController < ApplicationController
	before_filter :staff_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	verify :method=>:delete, :only=>[:destroy], :redirect_to=>{:action=>:show}
	
	# site page index (page tree?)
	def index
		@section = 'pages'
		if params[:id] and params[:id].to_i > 0
			@page = Page.find(params[:id], :include=>:children)
			@pages = @page.children
			@page_title = "Site Index: #{@page.title}"
		elsif !(params[:key].blank?)
			@page = nil
			@pages = Page.find_by_key(params[:key])
			@page_title = "Site Index: ‘#{params[:key]}’"
		else
			# find all top-level pages
			@page = Page.find_home
			if @page
				conditions = ['(pages.parent_id IS NULL OR pages.parent_id = ?) AND pages.id != ?',
					@page.id, @page.id]
			else
				conditions = ['pages.parent_id IS NULL']
			end
			@pages = Page.find(:all,
				:conditions=>conditions,
				:order=>'pages.title',
				:include=>:children)
			@page_title = "Site Index"
		end
		respond_to do |format|
			format.html # index.html.erb
			format.js   { render :partial=>'page', :collection=>@pages }
			format.xml  { render :xml => @pages.to_xml }
		end
	end
	
	# display a page
	def show
		@page = Page.find(params[:id])
		if @page.is_a? Page
			@page_title = @page.title
			@content_for_description = @page.description
			respond_to do |format|
				format.html # show.rhtml
				format.xml  { render :xml => @page.to_xml }
			end
		elsif @page.is_a? String
			# Redirect
			redirect_to @page
		elsif @page
			# FIXME: render the show action for @page.class controller
		else
			missing
		end
	end
	
	# form for adding a page
	def new
		@page = Page.new(params[:page])
		@page.user = current_user
		@parent = Page.find(params[:id]) rescue nil
		@page.parent = @parent
		@page_title = 'New Page'
		@section = 'pages'
	end
	
	# create a new page
	def create
		self.new
		@page.save!
		flash[:notice] = 'New Page was successfully saved.'
		redirect_to @page.sitepath
	#rescue NoMethodError
	#	self.new
	#	render :action=>:new
	rescue ActiveRecord::RecordInvalid
		#self.new
		@section = 'pages'
		render :action=>:new
	rescue
		flash.now[:error] = 'An error occurred while trying to save your new Page.'
		#self.new
		@section = 'pages'
		render :action=>:new
	end
	
	# form for editing a page
	def edit
		@page = Page.find(params[:id])
		if current_user.admin? or @page.user == current_user
			@page_title = "Edit ‘#{@page.title}’"
			@section = 'pages'
		else
			flash[:error] = "You do not have permission to edit the requested page (‘#{params[:id]}’)."
			redirect_to page_path(@page)
			@page = nil
		end
	rescue ActiveRecord::RecordNotFound
		flash[:warning] = "Could not find a page matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	# update a page
	def update
		self.edit
		if response.redirected_to
			# can’t update - was caught in edit
		else
			@page.editor = current_user
			if params[:page] && params[:page].size > 0 && @page.update_attributes(params[:page])
				flash[:notice] = "Updated information for ‘#{@page.title}’."
				redirect_to page_path(@page)
			else
				# failed to save, back to edit form
				@section = 'pages'
				render :action=>:edit
			end
		end
	end
	
	# delete a page
	def destroy
		@page = Page.find(params[:id])
		@page.destroy
		flash[:notice] = "The page ‘#{@page.title}’ has been permanently removed."
		redirect_to pages_path
	rescue ActiveRecord::RecordNotFound
		flash[:warning] = "Could not find a page matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	# report an error result
	def error
		@page_title = '500 Error'
		@url_path = get_path
		flash.now[:error] = "An error occurred while attempting to access ‘#{@path}’."
		render :action=>'error', :status=>'500 Error'
	end
	
	
end