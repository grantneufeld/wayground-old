class GroupsController < ApplicationController
	before_filter :staff_or_admin_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	
	def index
		@section = 'groups'
		@key = params[:key]
		@groups = Group.paginate(
			:per_page=>10, :page=>params[:page], :order=>'groups.name',
			:conditions=>Group.search_conditions({:only_visible=>true, :u=>current_user, :key=>@key})
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
	
	# display a list of groups belonging to this group
	def groups
		@section = 'groups'
		@subsection = 'groups'
		@group = Group.find(params[:id])
		@groups = @group.children
		@page_title = "Group: #{@group.name}: Subgroups"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def new
		@section = 'groups'
		@group = Group.new(params[:group])
		@group.creator = @group.owner = current_user
		@page_title = 'New Group'
	end
	# subgroup is a version of new when the user wants to create a new subgroup for a group
	def subgroup
		@section = 'groups'
		@parent = Group.find(params[:id])
		@group = Group.new(params[:group])
		@group.parent = @parent
		@group.creator = @group.owner = current_user
		@page_title = "Group: #{@parent.name}: New Subgroup"
		render :action=>'new'
	end
	
	def create
		@parent = Group.find(params[:id]) rescue nil
		@group = Group.new(params[:group])
		@group.parent = @parent
		@group.creator = @group.owner = current_user
		@group.save!
		flash[:notice] = 'New group was successfully saved.'
		redirect_to :action=>'show', :id=>@group
	rescue ActiveRecord::RecordInvalid
		@section = 'groups'
		@page_title = @parent.nil? ? 'New Group' : "Group: #{@parent.name}: New Subgroup"
		render :action=>:new
	end
	def createsub
		create
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
