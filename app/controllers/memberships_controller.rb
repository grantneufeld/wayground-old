class MembershipsController < ApplicationController
	#before_filter :staff_required,
	#	:only=>[:new, :create, :edit, :update, :destroy]
	before_filter :set_group
	#before_filter :group_member_mod_required,
	#	:only=>[:new, :create, :edit, :update, :destroy]
	
	def index
		# TODO: Key search for memberships controller index action
		@memberships = @group.memberships
		@page_title = "#{@group.name} Memberships"
		@key = params[:key]
		unless @key.blank?
			@page_title << ": ‘#{@key}’"
		end
	end
	
	def show
		@membership = @group.memberships.find(params[:id])
		@page_title = "#{@group.name} Membership for #{@membership.user.nickname}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	# assumes @group and @user have been set
	# returns nil if caller should not proceed, a Membership if successful
	def new_for_user
		# check if there’s already a membership for the user in the group
		@membership = Membership.find_for(@group, @user)
		if @membership
			# TODO handle case where user is admin to allow selection of user to add
			if @user == current_user
				# TODO handle rejoining if !(@membership.active?)
				flash[:warning] = 'You are already a member of the group.'
			else
				flash[:warning] = 'That user is already a member of the group.'
			end
			redirect_to group_membership_path(@group, @membership)
			return nil
		end
		@membership = @group.memberships.new(params[:membership])
		@membership.user = @user
		@membership
	end
	# access can be a symbol or an array of symbols
	# expects @group to be set
	def require_access_for_user(access)
		@current_membership = Membership.find_for(@group, current_user)
		if params[:user_id].blank?
			@user = current_user
		elsif @current_membership.nil?	
			# non-members don’t have access permission
			access_denied
			return nil
		else
			if access.is_a? Symbol
				can_access = @current_membership.has_access_to?(access)
			elsif access.is_a? Array
				can_access = false
				access.each do |a|
					can_access ||= @current_membership.has_access_to?(a)
				end
			end
			if can_access
				@user = User.find(params[:user_id])
			else
				# user doesn’t have required access permission
				access_denied
				return nil
			end
		end
		@user
	end
	def new_
		if @user
			return new_for_user
		else
			# didn’t find a match for the user_id
			flash[:error] = "No user matches the requested id (#{params[:user_id].to_i})"
			redirect_to group_path(@group)
			return nil
		end
	end
	def new
		@page_title = "#{@group.name}: New Membership"
		if really_logged_in?
			return unless require_access_for_user([:inviting, :manage_members])
			# check if there’s already a membership for the user in the group
			if @user
				new_for_user
			else
				# didn’t find a match for the user_id
				flash[:error] = "No user matches the requested id (#{params[:user_id].to_i})"
				redirect_to group_path(@group)
			end
		else
			# not logged-in, so need to create new user
			@user = User.new(params[:user])
			# maybe store url to return to if user is logging in (store_location)
			flash[:notice] = 'You are not logged-in, so you will need to register as a new user, or login to your existing account.'
		end
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	# SCENARIOS
	# non-member signing up
	# non-member requesting invite
	# member already signed up
	# member with can_manage_members or is_admin or user.staff adding member
	# member with can_invite or is_admin or user.staff inviting member
	# member with can_manage_members or is_admin or user.staff BULK adding members
	# member with can_invite or is_admin or user.staff BULK inviting members
	def create
		self.new
		if response.redirected_to
			# can’t create - was caught in new
		else
			# TODO: the assignment of @membership should be pulled into a separate method shared across action calls (e.g., new, create)
			@membership ||= @group.memberships.new(params[:membership])
			@membership.user ||= @user
			@membership.save!
			flash[:notice] = 'New membership was successfully saved.'
			redirect_to group_membership_path(@group, @membership)
		end
	rescue ActiveRecord::RecordInvalid
		@page_title = "#{@group.name}: New Membership"
		render :action=>:new
	end
	
	def edit
		@membership = Membership.find(params[:id])
		@page_title = "Edit Membership for #{@membership.user.nickname}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def update
		self.edit
		if response.redirected_to
			# can’t update - was caught in edit
		else
			if params[:membership] && params[:membership].size > 0 && @membership.update_attributes(params[:membership])
				flash[:notice] = "Updated membership information for #{@membership.user.nickname}."
				redirect_to group_membership_path(@group, @membership)
			else
				# failed to save, back to edit form
				render :action=>:edit
			end
		end
	end
	
	def destroy
		@membership = Membership.find(params[:id], :include=>:user)
		@membership.destroy
		flash[:notice] = "The membership for ‘#{@membership.user.nickname}’ has been permanently removed."
		redirect_to group_memberships_path(@group)
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	
	protected
	
	def set_group
		@section = 'groups'
		@group = Group.find(params[:group_id])
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def group_member_mod_required
		has_permission = true
		has_permission = access_denied if current_user.nil?
		unless !has_permission || (@group.owner == current_user)
			m = Membership.find_for(@group, current_user)
			has_permission = access_denied unless m && (m.is_admin || m.can_manage_members)
		end
		has_permission
	end
	
end
