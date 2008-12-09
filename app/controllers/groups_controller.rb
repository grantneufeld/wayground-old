class GroupsController < ApplicationController
	before_filter :staff_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	
	def index
		@section = 'groups'
		@key = params[:key]
		@groups = Group.paginate(
			:per_page=>10, :page=>params[:page], :order=>'groups.name',
			:conditions=>Group.search_conditions(true, current_user, @key)
			)
		@page_title = 'Groups'
		unless @key.blank?
			@page_title << ": ‘#{@key}’"
		end
	end
	
	def show
		@section = 'groups'
		@group = Group.find(params[:id])
		if current_user
			@membership = @group.memberships.find(:first,
				:conditions=>['memberships.user_id = ?', current_user.id])
		else
			@membership = nil
		end
		@page_title = "Group: #{@group.name}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def new
		@section = 'groups'
		@group = Group.new(params[:group])
		@group.creator = @group.owner = current_user
		@page_title = 'New Group'
	end
	
	def create
		@group = Group.new(params[:group])
		@group.creator = @group.owner = current_user
		@group.save!
		flash[:notice] = 'New group was successfully saved.'
		redirect_to :action=>'show', :id=>@group
	rescue ActiveRecord::RecordInvalid
		@section = 'groups'
		@page_title = 'New Group'
		render :action=>:new
	end
	
	def edit
		@section = 'groups'
		@group = Group.find(params[:id])
		@page_title = "Edit Group: #{@group.name}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def update
		self.edit
		if response.redirected_to
			# can’t update - was caught in edit
		else
			if params[:group] && params[:group].size > 0 && @group.update_attributes(params[:group])
				flash[:notice] = "Updated information for ‘#{@group.name}’."
				redirect_to({:action=>'show', :id=>@group})
			else
				# failed to save, back to edit form
				render :action=>:edit
			end
		end
	end
	
	def destroy
		@group = Group.find(params[:id])
		@group.destroy
		flash[:notice] = "The group ‘#{@group.name}’ has been permanently removed."
		redirect_to groups_path
	rescue ActiveRecord::RecordNotFound
		missing
	end
end
