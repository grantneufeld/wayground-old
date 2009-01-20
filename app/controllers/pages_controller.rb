class PagesController < ApplicationController
	protect_from_forgery :except=>:content_type_switch
	before_filter :staff_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	
	# site page index (page tree?)
	def index
		@section = 'pages'
		@key = params[:key]
		if params[:id] and params[:id].to_i > 0
			@page = Page.find(params[:id], :include=>[:children, :path])
			@pages = @page.children
			@key = nil
			@page_title = "Site Index: #{@page.title}"
		elsif !(@key.blank?)
			@page = nil
			@pages = Page.find_by_key(@key)
			@page_title = "Site Index: ‘#{params[:key]}’"
		else
			# find all top-level pages
			@page = nil
			@pages = Page.find_homes
			#if @page
			#	conditions = ['(pages.parent_id IS NULL OR pages.parent_id = ?) AND pages.id != ?',
			#		@page.id, @page.id]
			#else
			#	conditions = ['pages.parent_id IS NULL']
			#end
			#@pages = Page.find(:all,
			#	:conditions=>conditions,
			#	:order=>'pages.title',
			#	:include=>:children)
			@page_title = "Site Index"
		end
		respond_to do |format|
			format.html # index.html.erb
			format.js   { render :action=>'index_sublist', :layout=>false }
			format.xml  { render :xml => @pages.to_xml }
		end
	end
	
	# display a page
	def show
		@page = Page.find(params[:id])
		if @page
			@page_title = @page.is_home? ? nil : @page.title
			@content_for_description = @page.description
			respond_to do |format|
				format.html # show.rhtml
				format.xml  { render :xml => @page.to_xml }
			end
		else
			missing
		end
	end
	
	# form for adding a page
	def new
		pre_new
	end
	
	# create a new page
	def create
		pre_new
		@page.save!
		flash[:notice] = 'New Page was successfully saved.'
		redirect_to @page.sitepath
	#rescue NoMethodError
	#	render :action=>:new
	rescue ActiveRecord::RecordInvalid
		render :action=>:new
	rescue
		flash.now[:error] = 'An error occurred while trying to save your new Page.'
		render :action=>:new
	end
	
	# form for editing a page
	def edit
		pre_edit
	rescue ActiveRecord::RecordNotFound
		flash[:warning] = "Could not find a page matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	rescue Wayground::UserWithoutAccessPermission
		flash[:error] = "You do not have permission to edit the requested page (‘#{params[:id]}’)."
		redirect_to page_path(@page)
		@page = nil
	end
	
	# update a page
	def update
		pre_edit
		@page.editor = current_user
		if params[:chunks]
			@page.chunks = Chunk.create_from_param_hash(params[:chunks])
		end
		if params[:page] && params[:page].size > 0 && @page.update_attributes(params[:page])
			flash[:notice] = "Updated information for ‘#{@page.title}’."
			redirect_to page_path(@page)
		else
			# failed to save, back to edit form
			@section = 'pages'
			render :action=>:edit
		end
	rescue ActiveRecord::RecordNotFound
		flash[:warning] = "Could not find a page matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	rescue Wayground::UserWithoutAccessPermission
		flash[:error] = "You do not have permission to edit the requested page (‘#{params[:id]}’)."
		redirect_to page_path(@page)
		@page = nil
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
	
	# handle switching of content_type within edit form
	def content_type_switch
		@old_content_type = params[:old_content_type]
		@content_type = params[:content_type];
		if @old_content_type != @content_type
			@content = render_to_string :partial=>'convert_content',
				:locals=>{:content=>params[:content],
					:from_type=>@old_content_type,
					:to_type=>@content_type}
		else
			@content = params[:content]
		end
		@page = Page.new(:content=>@content, :content_type=>@content_type)
		#render :layout=>false
		respond_to do |format|
			format.html # index.html.erb
			format.js   { render :layout=>false }
			format.xml  { render :xml=>@page.to_xml }
		end
	end
	
	def new_chunk
		#@part = params[:part]
		#@chunk_type = params[:type]
		#@position = params[:position]
		@chunk = Chunk.create(params)
		respond_to do |format|
			format.html # index.html.erb
			format.js   { render :layout=>false }
			format.xml  { render :xml=>@chunk.to_xml }
		end
	end
	
	# report an error result
	def error
		@page_title = '500 Error'
		@url_path = get_path
		flash.now[:error] = "An error occurred while attempting to access ‘#{@path}’."
		render :action=>'error', :status=>'500 Error'
	end
	
	
	protected
	
	def pre_new
		@section = 'pages'
		@page_title = 'New Page'
		if params[:page]
			page_type = params[:page].delete(:type)
		else
			page_type = nil
		end
		if page_type == 'Article'
			@page = Article.new(params[:page])
		else
			@page = Page.new(params[:page])
		end
		@page.parent = Page.find(params[:id]) rescue nil
		#@page.parent = @parent
		begin
			@page.site = Site.find(params[:site_id])
		rescue ActiveRecord::RecordNotFound
			@page.site = @page.parent.nil? ? nil : @page.parent.site
		end
		#if @site
		#	@page.site = @site
		#else
		#	@page.site_id = 0
		#end
		@page.user = current_user
		@page.chunks = Chunk.create_from_param_hash(params[:chunks]) if params[:chunks]
	end
	
	def pre_edit
		@page = Page.find(params[:id])
		if current_user.admin? or current_user.staff? or @page.user == current_user
			@section = 'pages'
			@page_title = "Edit ‘#{@page.title}’"
			begin
				@page.site = Site.find(params[:site_id])
			rescue ActiveRecord::RecordNotFound
				#@site = nil
			end
			#if @site
			#	@page.site = @site
			#end
		else
			raise Wayground::UserWithoutAccessPermission
		end
	end
end
