class ListitemsController < ApplicationController
	before_filter :activation_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	before_filter :setup
	
	def new
		pre_new
	rescue Wayground::NilObject
		flash[:error] = @err_msg
		redirect_to lists_path
	end
	
	def create
		pre_new
		@success = @listitem.save
		if @success
			message = "The #{@listitem.item.class.name} was added to your “#{@list.title}” list."
			respond_to do |format|
				format.html do
					flash[:notice] = message
					redirect_to @listitem.item
				end
				format.js { flash.now[:notice] = message }
				format.xml { render :xml=>@listitem.to_xml }
			end
		else
			flash.now[:error] = "Unable to add the #{@listitem.item.class.name} to your “#{@list.title}” list."
			respond_to do |format|
				format.html { render :action=>'new' }
				format.js {}
				format.xml {}
			end
		end
	rescue Wayground::NilObject
		respond_to do |format|
			format.html do
				flash[:error] = @err_msg
				redirect_to lists_path
			end
			format.js do
				flash.now[:error] = @err_msg
			end
			format.xml {}
		end
	end 
	
	def destroy
		@listitem = Listitem.find(params[:id])
		if @listitem.list.user == current_user or current_user.admin?
			@listitem.destroy
			@success = true
		end
		respond_to do |format|
			format.html do
				if @success
					flash[:notice] = "The #{@listitem.item.class.name} has been removed from your “#{@list.title}” list."
					redirect_to lists_path
				else
					flash[:error] = 'That is not a list you have access to modify.'
					redirect_to account_users_path
				end
			end
			format.js do
				if @success
					@listitem_count = @list.listitems.count
					flash.now[:notice] = "The #{@listitem.item.class.name} has been removed from your “#{@list.title}” list."
				else
					flash.now[:error] = 'That is not a list you have access to modify.'
				end
			end
			format.xml {}
		end
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	
	protected
	
	def setup
		if params[:list_id].blank?
			@list = List.find_default_list_for_user(current_user)
		else
			@list = List.find(params[:list_id]) rescue ActiveRecord::RecordNotFound
		end
		if @list.nil?
			@list = List.new(:title=>'')
			@list.user = current_user
		end
		@section = 'lists'
		@page_title = @list.nil? ? '' : "#{@list.title}: "
	end
	
	def pre_new
		@listitem = @list.listitems.new(params[:listitem])
		@listitem.item_type ||= params[:item_type]
		@listitem.item_id ||= params[:item_id]
		@page_title += 'Add item to your list'
		if @listitem.item.nil?
			@err_msg = 'No item was specified — nothing to add to a list.'
			raise Wayground::NilObject
		end
	end
end
