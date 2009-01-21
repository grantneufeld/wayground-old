class EventsController < ApplicationController
	before_filter :staff_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	
	# special parameter ‘past’ includes past events if set,
	# otherwise, only upcoming events are shown
	def index
		@section = 'events'
		@key = params[:key]
		restrict = params[:past].blank? ? :upcoming : nil
		@max = params[:max].to_i
		@max = 10 if @max < 1
		@page_title = 'Events'
		@page_title += ": ‘#{@key}’" unless @key.blank?
		@page_title = "Upcoming #{@page_title}" if restrict == :upcoming
		@events = Event.paginate(
			:per_page=>@max, :page=>params[:page], :order=>Event.default_order,
			:include=>Event.default_include,
			:conditions=>Event.search_conditions(
				{:u=>current_user, :key=>@key, :restrict=>restrict})
			)
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
		# anti-spam
		unless (params[:event].nil? or params[:event][:url].blank?) and (params[:schedule].nil? or params[:schedule][:email].blank?)
			# looks like a non-human is trying to auto-fill the form
			raise Wayground::SpammerDetected
		end
		@event.save!
		flash[:notice] = 'New event was successfully saved.'
		redirect_to :action=>'show', :id=>@event
	rescue Wayground::SpammerDetected
		block_spammer
		# skip the save, but let them think it was saved
		flash.now[:notice] = 'New event was successfully saved.'
		@page_title = "Event: #{@event.title}"
		render :action=>:show
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
