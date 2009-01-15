class EventsController < ApplicationController
	before_filter :staff_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	
	def index
		@section = 'events'
		@key = params[:key]
		@events = Event.paginate(
			:per_page=>10, :page=>params[:page], :order=>'events.title',
			:conditions=>Event.search_conditions({:u=>current_user, :key=>@key})
			)
		@page_title = 'Events'
		unless @key.blank?
			@page_title << ": ‘#{@key}’"
		end
	end
	
	def show
		@section = 'events'
		@event = Event.find(params[:id])
		@page_title = "Event: #{@event.title}"
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def new
		pre_new
	end
	
	def create
		pre_new
		@event.save!
		flash[:notice] = 'New event was successfully saved.'
		redirect_to :action=>'show', :id=>@event
	rescue ActiveRecord::RecordInvalid
		render :action=>:new
	end
	
	def edit
		pre_edit
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def update
		pre_edit
		if params[:event] && params[:event].size > 0 && @event.update_attributes(params[:event])
			flash[:notice] = "Updated information for ‘#{@event.title}’."
			redirect_to({:action=>'show', :id=>@event})
		else
			# failed to save, back to edit form
			render :action=>:edit
		end
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def destroy
		@event = Event.find(params[:id])
		@event.destroy
		flash[:notice] = "The event ‘#{@event.title}’ has been permanently removed."
		redirect_to events_path
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	
	protected
	
	def pre_new
		@section = 'events'
		@event = Event.new(params[:event])
		@event.user = current_user
		unless params[:id].blank?
			@event.parent = Event.find(params[:id]) rescue ActiveRecord::RecordNotFound
		end
		@page_title = 'New Event'
	end
	
	def pre_edit
		@section = 'events'
		@event = Event.find(params[:id])
		@page_title = "Edit Event: #{@event.title}"
	end
end
