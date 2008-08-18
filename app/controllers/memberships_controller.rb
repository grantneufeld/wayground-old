class MembershipsController < ApplicationController
	#before_filter :staff_required,
	#	:only=>[:new, :create, :edit, :update, :destroy]
	before_filter :set_group
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
		# TODO: PERMISSIONS ON ADDING NEW MEMBERSHIP!!! •••
		@user = User.find(params[:user_id]) unless params[:user_id].blank?
		@membership = @group.memberships.new(params[:membership])
		@membership.user = @user
		@page_title = "#{@group.name}: New Membership"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def create
		
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
end
