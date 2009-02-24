class EmailMessagesController < ApplicationController
	# TODO: more flexible access permissions for sending email messages
	before_filter :staff_or_admin_required
	before_filter :setup
	
	def index
		@key = params[:key]
		@max = params[:max].to_i
		@max = 10 if @max < 1
		@page_title += 'Messages'
		@page_title += ": ‘#{@key}’" unless @key.blank?
		@email_messages = EmailMessage.paginate(
			:per_page=>@max, :page=>params[:page], :order=>EmailMessage.default_order,
			:include=>EmailMessage.default_include,
			:conditions=>EmailMessage.search_conditions(
				{:item=>@group, :u=>current_user, :key=>@key})
			)
	end
	
	def show
		@email_message = EmailMessage.find(params[:id])
		if @email_message.status == 'draft'
			@page_title += 'Send Message'
			render :action=>:new
		else
			@page_title += "Message #{@email_message.id}"
		end
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def new
		pre_new
		@page_title += 'Send Message'
	end
	
	def create
		pre_new
		process_email_message_submission
	end
	
	def edit
		@email_message = EmailMessage.find(params[:id])
		@page_title += 'Send Message'
		render :action=>:new
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def update
		@email_message = EmailMessage.find(params[:id])
		process_email_message_submission
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	def destroy
		
	end
	
	
	protected
	
	def setup
		if params[:group_id].blank?
			@group = nil
		else
			@group = Group.find(params[:group_id]) rescue ActiveRecord::RecordNotFound
		end
		@section = @group.nil? ? 'messages' : 'groups'
		@subsection = @group.nil? ? nil : 'message'
		@page_title = @group.nil? ? '' : "#{@group.title}: "
	end
	
	def pre_new
		@email_message = EmailMessage.new(params[:email_message])
		@email_message.status = 'draft'
		@email_message.user = current_user
		@email_message.item = @group
		@email_message.from ||= current_user.email_addresses[0].to_s
	end
	
	def process_email_message_submission
		@email_message.save!
		if params[:process] == 'Save Draft'
			flash[:notice] = 'Email message draft saved.'
			render :action=>:new
		else
			@email_message.deliver!
			flash[:notice] = 'Email Message sent.'
			redirect_to :action=>'show', :id=>@email_message
		end
	rescue ActiveRecord::RecordInvalid
		render :action=>:new
	rescue Wayground::DeliveryFailure
		flash[:error] = 'Message delivery failed.'
		render :action=>:new
	end
	
end
