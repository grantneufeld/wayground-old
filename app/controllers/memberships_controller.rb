class MembershipsController < ApplicationController
	before_filter :activation_required,
		:only=>[:new, :create, :edit, :update, :destroy]
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
	
	def new
		pre_new
	rescue ActiveRecord::RecordNotFound
		missing
	rescue Wayground::UserWithoutAccessPermission	
		access_denied
	rescue Wayground::CannotAddUserMembership
		redirect_to group_path(@group)
	end
	
	def create
		pre_new
		@membership.save!
		flash[:notice] = 'New membership was successfully saved.'
		redirect_to group_membership_path(@group, @membership)
	rescue ActiveRecord::RecordInvalid
		#@page_title = "#{@group.name}: New Membership"
		render :action=>:new
	rescue ActiveRecord::RecordNotFound
		missing
	rescue Wayground::UserWithoutAccessPermission	
		access_denied
	rescue Wayground::CannotAddUserMembership
		redirect_to group_path(@group)
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
	
	# SCENARIOS
	# non-member signing up
	# non-member requesting invite
	# member already signed up
	# member with can_manage_members or is_admin or user.staff adding member
	# member with can_invite or is_admin or user.staff inviting member
	# member with can_manage_members or is_admin or user.staff BULK adding members
	# member with can_invite or is_admin or user.staff BULK inviting members
	# TODO: Handle group admins inviting (rather than just adding) a user
	# TODO: group admins bulk adding/inviting users
	def pre_new
		if really_logged_in?
			# the user must be trying to self-add, or must have admin access to the group
			if params[:user_id].blank?
				@user = current_user
			else
				@user = User.find(params[:user_id])
			end
			can_admin = false
			unless (@user == current_user)
				can_admin = require_group_access([:inviting, :manage_members])
			end
			
			# check existing membership status
			@membership = @group.user_membership(@user)
			if @membership.nil?
				if @group.is_invite_only and !can_admin
					# TODO: Handle group membership invite requests
					flash[:error] = 'The group is invitation only'
					raise Wayground::CannotAddUserMembership
				else
					@membership = @group.memberships.new(params[:membership])
					@membership.user = @user
				end
			elsif @membership.active?
				flash[:notice] = 'User is already a member of the group'
				raise Wayground::CannotAddUserMembership
			elsif @membership.blocked?
				flash[:warning] = 'User does not have access to the group'
				raise Wayground::CannotAddUserMembership
			elsif @membership.invited?
				# clear invitation status since user is now being added
				@membership.invited_at = nil
				# TODO: add a joined_at field to memberships and set it here
			elsif @membership.expired?
				# TODO: Future: may need more sophisticated handling of renewal of expired memberships
				@membership.expires_at = nil
			end
		else
			# not logged-in, so need to create new user
			@user = User.new(params[:user])
			@membership = @group.memberships.new(params[:membership])
			@membership.user = @user
			# maybe store url to return to if user is logging in (store_location)
			flash[:notice] = 'You are not logged-in, so you will need to register as a new user, or login to your existing account.'
		end
		@page_title = "#{@group.name}: New Membership"
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
	
	# access can be a symbol or an array of symbols
	# expects @group to be set
	def require_group_access(access)
		raise Wayground::UserWithoutAccessPermission if current_user.nil?
		unless current_user.staff? or current_user.admin? or (@group.owner == current_user)
			@current_membership = Membership.find_for(@group, current_user)
			if @current_membership.nil?	
				# non-members don’t have access permission
				raise Wayground::UserWithoutAccessPermission
			else
				unless @current_membership.has_access_to?(access)
					# user doesn’t have required access permission
					raise Wayground::UserWithoutAccessPermission
				end
			end
		end
	end
end
