class PathsController < ApplicationController
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
			if @item.is_a? Page
				@page_title = @item.title
				@content_for_description = @item.description
				@page = @item
				respond_to do |format|
					format.html { render :template=>'pages/show' }
					format.xml  { render :xml => @item.to_xml }
				end
			# TODO: support other classes of item
			end
		end
	end

	def new
	end

	def create
	end

	def edit
	end

	def update
	end

	def destroy
	end

end
