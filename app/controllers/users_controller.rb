class UsersController < ApplicationController
	before_filter :login_required, :only=>[:edit, :account]
		#, :change_password]
	before_filter :admin_required, :only=>[:index, :show]
	
	# list users, but only for admins
	def index
		@users = User.paginate :per_page=>10, :page=>params[:page],
			:order=>'users.nickname'
		@page_title = 'User List'
	end
	
	# show a user, but only for admins
	def show
		@user = User.find(params[:id])
		if @user
			@page_title = "User: #{@user.title}"
		end
	rescue ActiveRecord::RecordNotFound
		flash[:notice] =
			"Could not find a user matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	# user’s public profile
	def profile
		if params[:id].match /\A[0-9]+\z/
			@user = User.find(params[:id])
		else
			@user = User.find_by_subpath(params[:id])
		end
		raise ActiveRecord::RecordNotFound if @user.nil?
		@page_title = "User: #{@user.title}"
	rescue ActiveRecord::RecordNotFound
		flash[:notice] =
			"Could not find a user matching the requested id (‘#{params[:id]}’)."
		redirect_to root_path
	end
	
	# new user registration form
	def new
		@user = User.new(params[:user])
		@user.valid? if params[:user]
		@user.time_zone = Time.zone.name unless params[:user]
		@page_title = 'New User Registration'
	end
	
	# new user registration submission
	def create
		cookies.delete 'auth_token'
		reset_session
		
		self.new
		# User model doesn’t require email, but web login does
		@user.email_required = true
		@user.login_at = Time.current
		@user.save!
		self.current_user = @user
		
		# send email confirmation
		if Notifier.deliver_signup_confirmation(@user)
			flash[:notice] = "Thanks for signing up! A confirmation email has been sent to you at #{@user.email}. Please look for a message from #{(WAYGROUND['SENDER'].gsub(/[><]/){|x|{'>'=>'&gt;','<'=>'&lt;'}[x]})}."
		else
			flash[:error] = "Your new user account has been created, but there was an error when trying to send an email confirmation. Please contact the website administrator about this problem. #{WAYGROUND['EMAIL']}"
		end
		
		redirect_to '/users/account'
	rescue ActiveRecord::RecordInvalid
		render :action=>'new'
	end
	
	# user registration confirmation
	def activate
		@user = current_user
		if @user
			if params[:activation_code].blank?
				flash[:notice] = 'No activation code was supplied. Please confirm that you are using the complete activation link you were given.'
			elsif @user.activated?
				flash[:notice] = 'Your account has already been activated.'
			elsif @user.activate(params[:activation_code])
				flash[:notice] = 'Your user account has now been activated. Thank-you for confirming it.'
				unless Notifier.deliver_activated(@user)
					# don't bother notifying of email failure since it's not critical
				end
			else
				flash[:notice] = 'The supplied activation code did not match the one in your user account. Please ensure you are logged in as the correct user, and that you used the complete activation web link.'
			end
			redirect_to account_users_path
		else
			flash[:notice] = 'You must re-login first to activate your account.'
			store_location
			redirect_to login_path
		end
	end
	
	# user account information
	def account
		@user = current_user
		if @user
			@page_title = 'User Account'
		else
			flash[:notice] = 'You must be logged-in to access your user account.'
			redirect_to '/login'
		end
	end
	
	# user edit form
	def edit
		if current_user && current_user.id == params[:id].to_i
			@user = current_user
		elsif current_user && current_user.admin
			@user = User.find(params[:id])
		else
			@user = nil
		end
		if @user
			blank_location = Location.new()
			blank_location.id = 0
			if @user.locations && @user.locations.size > 0
				@locations = @user.locations + [blank_location]
			else
				@locations = [blank_location]
			end
			@page_title = "Edit User: #{@user.title}"
		else
			#flash[:notice] = 'You do not have permission to access the requested action. Please login as a user with sufficient permission.'
			#redirect_to '/login'
			access_denied
		end
	rescue ActiveRecord::RecordNotFound
		flash[:notice] =
			"Could not find a user matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	def update
		if current_user && current_user.id == params[:id].to_i
			@user = current_user
		elsif current_user && current_user.admin
			@user = User.find(params[:id])
		else
			@user = nil
		end
		if @user
			params[:location].each_pair do |loc_id, location_params|
				loc_id = loc_id.to_i
				if loc_id > 0
					@user.locations.find(loc_id).update_attributes!(
						location_params)
				else
					blank_loc = true
					location_params.each_pair do |k, v|
						blank_loc = false unless v.blank?
					end
					unless blank_loc
						@user.locations << Location.new(location_params)
					end
				end
			end
			@user.update_attributes!(params[:user])
			
			flash[:notice] = 'User details updated.'
			if current_user == @user
				redirect_to account_users_path
			else
				redirect_to users_path
			end
		else
			access_denied
		end
	rescue ActiveRecord::RecordNotFound
		flash[:notice] =
			"Could not find a user matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	# TODO: user password change
	# TODO: user email change request
	# TODO: user email change confirm
	
end
