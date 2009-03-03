class EmailAddressesController < ApplicationController
	before_filter :staff_or_admin_required
	before_filter :setup
	
	def index
		@key = params[:key]
		@max = params[:max].to_i
		@max = 10 if @max < 1
		@page = params[:page].blank? ? nil : params[:page].to_i
		@email_addresses = EmailAddress.paginate(
			:per_page=>@max, :page=>@page, :order=>EmailAddress.default_order,
			:include=>EmailAddress.default_include,
			:conditions=>EmailAddress.search_conditions(
				{:item=>@user, :u=>current_user, :key=>@key})
			)
		@page_title += 'Email Addresses'
		@page_title += ": ‘#{@key}’" unless @key.blank?
		@page_title += " (#{@page})" if @page and @page > 1
	end
	
	def show
		@email_address = EmailAddress.find(params[:id])
		@page_title += "Email Address #{@email_address.id}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def new
		pre_new
	end
	
	def create
		pre_new
		@email_address.save!
		flash[:notice] = 'Email Address saved.'
		redirect_to :action=>'show', :id=>@email_address
	rescue ActiveRecord::RecordInvalid
		render :action=>:new
	end
	
	def edit
		@email_address = EmailAddress.find(params[:id])
		@page_title += "Edit Email Address #{@email_address.id}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def update
		@email_address = EmailAddress.find(params[:id])
		if params[:email_address] && params[:email_address].size > 0
			@email_address.update_attributes!(params[:email_address])
			flash[:notice] = 'Email Address updated.'
			redirect_to :action=>'show', :id=>@email_address
		else
			# no changes to save, back to edit form
			render :action=>:edit
		end
	rescue ActiveRecord::RecordInvalid
		render :action=>:edit
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def destroy
		@email_address = EmailAddress.find(params[:id])
		@email_address.destroy
		flash[:notice] = "The email address ‘#{@email_address.email}’ has been permanently removed."
		redirect_to :action=>:index
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	protected
	
	def setup
		if params[:user_id].blank?
			@user = nil
		else
			@user = User.find(params[:user_id]) # rescue ActiveRecord::RecordNotFound
		end
		@section = 'contacts'
		@page_title = @user.nil? ? '' : "#{@user.title}: "
	end
	
	def pre_new
		@email_address = EmailAddress.new(params[:email_address])
		@email_address.user = @user
		@page_title += "New Email Address"
	end
	
end
