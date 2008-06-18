class PathsController < ApplicationController
	before_filter :staff_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	verify :method=>:delete, :only=>[:destroy], :redirect_to=>{:action=>:show}
	
	def index
		@section = 'paths'
		if params[:key].blank?
			# find all paths
			@paths = Path.find(:all, :order=>'paths.sitepath', :include=>:item)
			@page_title = "Site Paths"
		else
			@path = nil
			@paths = Path.find_by_key(params[:key])
			@page_title = "Site Paths: ‘#{params[:key]}’"
		end
		respond_to do |format|
			format.html # index.rhtml
			format.xml  { render :xml => @paths.to_xml }
		end
	end

	def show
		if params[:id] and params[:id].to_i > 0
			@path = Path.find(params[:id])
			@page_title = "Path #{@path.sitepath}"
		else
			if params[:url].blank?
				@path = Path.find_home
			else
				path = get_path
				@path = Path.find(:first, :conditions=>
					['(sitepath = ? OR sitepath = ?)', path, "#{path}/"])
			end
		
			if @path.nil?
				missing
			elsif !(@path.redirect.blank?)
				redirect_to @path.redirect
			else
				@item = @path.item
				# TODO: handle security-access for private items
				if @item.is_a? Page
					@page_title = @item.title
					@content_for_description = @item.description
					@page = @item
					respond_to do |format|
						format.html { render :template=>'pages/show' }
						format.xml  { render :xml => @item.to_xml }
					end
				elsif @item.is_a? Document
					@document = @item
					disposition = @document.renderable? ? 'inline' : 'attachment'
					send_data @document.content, :type=>@document.content_type,
						:filename=>@document.filename, :disposition=>disposition
				# TODO: support other classes of item
				end
			end
		end
	end

	def new
		@path = Path.new(params[:path])
		@page_title = 'New Path'
		@section = 'paths'
	end
	
	def create
		@path = Path.new(params[:path])
		@path.save!
		flash[:notice] = 'New Path was successfully saved.'
		redirect_to :action=>'show', :id=>@path
	rescue ActiveRecord::RecordInvalid
		@page_title = 'New Path'
		@section = 'paths'
		render :action=>:new
	#rescue
	#	flash.now[:error] = 'An error occurred while trying to save your new Path.'
	#	@page_title = 'New Path'
	#	@section = 'paths'
	#	render :action=>:new
	end

	def edit
		@path = Path.find(params[:id])
		@page_title = "Edit ‘#{@path.sitepath}’"
		@section = 'paths'
	rescue ActiveRecord::RecordNotFound
		flash[:warning] = "Could not find a path matching the requested id (‘#{params[:id]}’)."
		redirect_to paths_path #:action=>'index'
	end

	def update
		self.edit
		if response.redirected_to
			# can’t update - was caught in edit
		else
			if params[:path] && params[:path].size > 0 && @path.update_attributes(params[:path])
				flash[:notice] = "Updated information for ‘#{@path.sitepath}’."
				redirect_to({:action=>'show', :id=>@path})
			else
				# failed to save, back to edit form
				@section = 'paths'
				render :action=>:edit
			end
		end
	end

	def destroy
		@path = Path.find(params[:id])
		@path.destroy
		flash[:notice] = "The path ‘#{@path.sitepath}’ has been permanently removed."
		redirect_to paths_path
	rescue ActiveRecord::RecordNotFound
		flash[:warning] = "Could not find a path matching the requested id (‘#{params[:id]}’)."
		redirect_to paths_path
	end

end
