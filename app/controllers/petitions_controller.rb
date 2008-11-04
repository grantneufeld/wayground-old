class PetitionsController < ApplicationController
	before_filter :staff_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	verify :method=>:delete, :only=>[:destroy], :redirect_to=>{:action=>:show}
	
	def index
		@section = 'petitions'
		@key = params[:key]
		@petitions = Petition.paginate(
			:per_page=>10, :page=>params[:page], :order=>'petitions.title',
			:conditions=>Petition.search_conditions(current_user, @key)
			)
		@page_title = 'Petitions'
		unless @key.blank?
			@page_title << ": ‘#{@key}’"
		end
	end
	
	def show
		@section = 'petitions'
		@petition = Petition.find(params[:id])
		@page_title = "Petition: #{@petition.title}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def new
		@section = 'petitions'
		@petition = Petition.new(params[:petition])
		@petition.user = current_user
		@page_title = 'New Petition'
	end
	
	def create
		@petition = Petition.new(params[:petition])
		@petition.user = current_user
		@petition.save!
		flash[:notice] = 'New petition was successfully saved.'
		redirect_to :action=>'show', :id=>@petition
	rescue ActiveRecord::RecordInvalid
		@section = 'petitions'
		@page_title = 'New Petition'
		render :action=>:new
	end
	
	def edit
		@section = 'petitions'
		@petition = Petition.find(params[:id])
		@page_title = "Edit Petition: #{@petition.title}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def update
		self.edit
		if response.redirected_to
			# can’t update - was caught in edit
		else
			if params[:petition] && params[:petition].size > 0 && @petition.update_attributes(params[:petition])
				flash[:notice] = "Updated information for ‘#{@petition.title}’."
				redirect_to({:action=>'show', :id=>@petition})
			else
				# failed to save, back to edit form
				render :action=>:edit
			end
		end
	end
	
	def destroy
		@petition = Petition.find(params[:id])
		@petition.destroy
		flash[:notice] = "The petition ‘#{@petition.title}’ has been permanently removed."
		redirect_to petitions_path
	rescue ActiveRecord::RecordNotFound
		missing
	end
end
