class PathsController < ApplicationController
	before_filter :staff_or_admin_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	
	def index
		@section = 'paths'
		@path = nil
		@page_title = "Site Paths"
		@page_title += ": ‘#{params[:key]}’" unless params[:key].blank?
		@paths = Path.find(:all,
			:conditions=>Path.search_conditions({:key=>params[:key], :u=>current_user}),
			:order=>Path.default_order, :include=>Path.default_include)
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
				@path = Path.find(:first, :conditions=>Path.search_conditions(
					{}, ['(sitepath = ? OR sitepath = ?)'], [path, "#{path}/"]))
			end
		
			if @path.nil?
				missing
			elsif !(@path.redirect.blank?)
				redirect_to @path.redirect
			else
				@item = @path.item
				# TODO: handle security-access for private items
				if @item.is_a? Page
					if @item.is_home?
						@section = 'home'
						@page_title = nil
					else
						@page_title = @item.title
					end
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
