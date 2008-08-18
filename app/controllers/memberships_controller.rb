class MembershipsController < ApplicationController
	#before_filter :staff_required,
	#	:only=>[:new, :create, :edit, :update, :destroy]
	before_filter :set_group
	before_filter :group_member_mod_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	verify :method=>:delete, :only=>[:destroy], :redirect_to=>{:action=>:show}
	
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
		@user = User.find(params[:user_id]) unless params[:user_id].blank?
		# check if there’s already a membership for the user in the group
		if @user
			@membership = Membership.find_for(@group, @user)
			if @membership
				flash[:warning] = 'That user is already a member of the group.'
				redirect_to group_membership_path(@group, @membership)
				return
			end
		end
		@membership = @group.memberships.new(params[:membership])
		@membership.user = @user
		@page_title = "#{@group.name}: New Membership"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def create
		self.new
		if response.redirected_to
			# can’t create - was caught in new
		else
			@membership.save!
			flash[:notice] = 'New membership was successfully saved.'
			redirect_to group_membership_path(@group, @membership)
		end
	rescue ActiveRecord::RecordInvalid
		@page_title = "#{@group.name}: New Membership"
		render :action=>:new
	end
	
	def edit
		
	end
	
	def update
		
	end
	
	def destroy
		
	end
	
	
	protected
	
	def set_group
		@section = 'groups'
		@group = Group.find(params[:group_id])
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
