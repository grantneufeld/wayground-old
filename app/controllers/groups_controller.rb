class GroupsController < ApplicationController
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
end
