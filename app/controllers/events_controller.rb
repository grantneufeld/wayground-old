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
		unmodified_subpath = @event.to_param
		# TODO: I’m clearly not doing something “The Rails Way” here. There’s got to be a better way to update a model and it’s sub-models all in one go.
		has_params = !(params[:event].nil? or params[:event].size == 0) and !(params[:schedule].nil? or params[:schedule].size == 0) and !(params[:location].nil? or params[:location].size == 0)
		if has_params
			@event.attributes = params[:event]
			@event.schedules[0].attributes = params[:schedule]
			@event.schedules[0].locations[0].attributes = params[:location]
			failed_validation = !(@event.valid?)
			failed_validation ||= !(@event.schedules[0].valid?)
			failed_validation ||= !(@event.schedules[0].locations[0].valid?)
		end
		if has_params and !failed_validation and (@event.schedules[0].locations[0].save and @event.schedules[0].save and @event.save)
			flash[:notice] = "Updated information for ‘#{@event.title}’."
			redirect_to({:action=>'show', :id=>@event})
		else
			# failed to save, back to edit form
			@event.subpath = unmodified_subpath
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
		# TODO: support multiple schedules
		@event.schedules << Schedule.new(params[:schedule])
		# TODO: support multiple locations
		@event.schedules[0].locations << Location.new(params[:location])
		@page_title = 'New Event'
	end
	
	def pre_edit
		@section = 'events'
		@event = Event.find(params[:id])
		@page_title = "Edit Event: #{@event.title}"
	end
end
