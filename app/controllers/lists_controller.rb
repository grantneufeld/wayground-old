class ListsController < ApplicationController
	before_filter :activation_required
	
	def index
		@page_title = 'Your Lists'
		@lists = List.find(:all, :conditions=>List.search_conditions(:user=>current_user),
			:order=>List.default_order, :include=>List.default_include)
	end

	def show
		@list = List.find(params[:id], :conditions=>List.search_conditions({:u=>current_user}))
		@page_title = (@list.user == current_user ? 'Your' : "#{@list.user.title}’s") + " List: #{@list.title}"
		if @list.listitems.size < 1
			flash.now[:notice] = 'The list is empty.'
		end
	rescue ActiveRecord::RecordNotFound
		missing
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
