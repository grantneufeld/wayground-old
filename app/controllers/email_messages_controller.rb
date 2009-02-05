class EmailMessagesController < ApplicationController
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
			:conditions=>EmailMessage.search_conditions({:u=>current_user, :key=>@key})
			)
	end
	
	def new
		
	end
	
	protected
	
	def setup
		@group = Group.find(params[:group_id]) rescue ActiveRecord::RecordNotFound
		@section = @group.nil? ? 'messages' : 'groups'
		@subsection = @group.nil? ? nil : 'message'
		@page_title = @group.nil? ? '' : "#{@group.title}: "
	end
end
