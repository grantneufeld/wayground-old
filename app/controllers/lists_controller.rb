class ListsController < ApplicationController
	before_filter :activation_required
	
	def index
		@page_title = 'Your Lists'
		@lists = Listitem.find_lists_for_user(current_user)
	end

	def show
		@page_title = "Your List: #{h(params[:id])}"
		@listitems = Listitem.find(:all, :order=>Listitem.default_order,
			:conditions=>Listitem.search_conditions(:title=>params[:id]),
			:include=>Listitem.default_include)
		if !@listitems or @listitems.size < 1
			flash.now[:notice] = 'The list is empty.'
		end
	end
	
	# deletes all the rows in the listitems table that match the current_user and the list title (id)
	def destroy
		conditions = ['listitems.user_id = ? AND listitems.title = ?',
			current_user.id, params[:id]]
		item_count = Listitem.count(:conditions=>conditions)
		if item_count > 0
			Listitem.delete_all(conditions)
			flash[:notice] = "The list" + (params[:id].blank? ? '' : " “#{params[:id]}”") +
				" has been permanently deleted. There were #{item_count} items referenced by it. (The items have not been deleted, only the list’s references to them.)"
		else
			flash[:error] = 'No such list.'
		end
		redirect_to lists_path
	end
end
