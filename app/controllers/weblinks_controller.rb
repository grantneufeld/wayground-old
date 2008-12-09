class WeblinksController < ApplicationController
	before_filter :activation_required, :only=>['new', 'create']
	before_filter :staff_required, :only=>['edit', 'update', 'destroy']
	before_filter :shared
	
	# common initialization
	def shared
		if params[:group_id]
			@item = Group.find(params[:group_id])
			@section = 'groups'
			# private groups restrict weblink access
			if !(@item.user_can_access?(current_user))
				access_denied
				return false
			end
		elsif params[:user_id]
			@item = User.find(params[:user_id])
			@section = 'users'
		else
			@item = nil
			@section = 'weblinks'
		end
		true
	rescue ActiveRecord::RecordNotFound
		missing
		false
	end
	
	# GET weblinks_url
	def index
		if @item.nil?
			@weblinks = nil
		else
			@weblinks = @item.weblinks
			@page_title = "#{@item.display_name} Weblinks"
		end
	end

	# GET weblink_url(:id=>1)
	def show
		@weblink = Weblink.find(params[:id], :include=>[:item])
		@page_title = (@item.nil? ? '' : "#{@item.display_name}: ") + "Weblink ‘#{@weblink.title}’"
	rescue ActiveRecord::RecordNotFound
		missing
	end

	# GET new_weblink_url
	def new
		@page_title = (@item.nil? ? '' : "#{@item.display_name}: ") + 'New Weblink'
		# return an HTML form for describing a new weblink
		@weblink = Weblink.new(params[:weblink])
		@weblink.user = current_user
		@weblink.item = @item
	end

	# POST weblinks_url
	def create
		# create a new weblink
		self.new
		@err_msg = nil
		begin
			unless @weblink.save
				@err_msg = 'Weblink save failed.'
			end
		rescue
			@err_msg = 'Weblink save failed.'
		end
		if request.xhr?
			render :action=>'create.rjs'
		else
			if @err_msg
				respond_to do |format|
					format.html { render :action=>"new" }
					format.xml  { render :xml=>@weblink.errors.to_xml }
				end
			else
				flash[:notice] = 'Weblink was successfully created.'
				respond_to do |format|
					format.html {
						redirect_to weblink_url(@weblink)}
					format.xml {head :created,
						:location=>weblink_url(@weblink)}
				end
			end
		end
	end

	# GET edit_weblink_url(:id=>1)
	def edit
		# return an HTML form for editing a specific weblink
		# TODO: allow more refined editing permissions so that non-staff/admin users can edit weblinks they've submitted (unless the weblink has been confirmed by staff/admin)
		@weblink = Weblink.find(params[:id], :include=>[:item])
		@page_title = "Edit Weblink ‘#{@weblink.title}’"
	end

	# PUT weblink_url(:id=>1)
	def update
		# find and update a specific weblink
		edit
		# only staff/admins can update listings, so mark as confirmed
		@weblink.is_confirmed = true
		if @weblink.update_attributes(params[:weblink])
			respond_to do |format|
				flash[:notice] = 'weblink was successfully updated.'
				format.html { redirect_to weblink_url(@weblink) }
				format.xml { head :ok }
			end
		else
			respond_to do |format|
    			format.html { render :action => "edit" }
    			format.xml { render :xml => @weblink.errors.to_xml }
			end
		end
	end

	# DELETE weblink_url(:id=>1)
	def destroy
		# TODO: Allow non-staff/admins to delete weblinks they added (unless the weblink has been confirmed by staff/admin)
		@weblink = Weblink.find(params[:id], :include=>:item)
		@weblink.destroy
		if request.xhr?
			render :action=>'destroy.rjs'
		else
			respond_to do |format|
				format.html {
					flash[:notice] = "The weblink (#{@weblink.id}) has been permanently removed."
					#if @item.is_a? Group
					#	redirect_to group_path(@item)
					#elsif @item.is_a? User
					#	redirect_to user_path(@item)
					#end
					if @item
						redirect_to @item
					else
						redirect_to weblinks_path
					end
				}
				format.xml { head(:ok) }
			end
		end
	rescue ActiveRecord::RecordNotFound
		missing
	end
end
