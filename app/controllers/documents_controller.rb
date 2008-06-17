class DocumentsController < ApplicationController
	before_filter :activation_required,
		:only=>[:new, :create, :edit, :update, :destroy]
	#before_filter :admin_required, :only=>[:index, :show]
	before_filter :setup
	
	verify :method=>:delete, :only=>[:destroy], :redirect_to=>{:action=>:show}
	
	# TODO: support private (restricted access) documents
	
	# return the document’s data (content)
	# expects the params:
	# :filename (maps to documents.filename)
	# :root (the full path up leading up to the filename. E.g., '/file/folder/')
	def data
		@filename = params[:filename].nil? ? nil : params[:filename].last
		# TODO: data action needs a way to determine whether the disposition should be inline or not — whether the file should be downloaded or displaye in(line) the browser.
		#disposition = (params[:show] == 'inline') ? 'inline' : params[:disposition]
		@document = Document.find_for_user(current_user, :first,
			:conditions=>['filename = ?', @filename])
		if @document
			disposition = @document.renderable? ? 'inline' : 'attachment'
			send_data @document.content, :type=>@document.content_type,
				:filename=>@document.filename, :disposition=>disposition
		else
			@url_path = "#{params[:root]}#{@filename}"
			flash.now[:error] =
				"Could not find the requested file ‘#{@filename}’"
			missing
		end
	end
	
	# list of documents
	def index
		# uses the will_paginate gem (paginate function)
		# TODO: customize value for per_page (allow user preference and/or use of params[:max])
		@documents = Document.paginate :per_page=>10, :page=>params[:page],
			:order=>'documents.filename',
			:conditions=>Document.search_conditions(
				false, current_user, params[:key])
		@page_title = 'Documents'
		@page_title += ": ‘#{params[:key]}’" unless params[:key].blank?
	end
	
	# information page for a document
	def show
		@document = Document.find_for_user(current_user, params[:id])
		@page_title = "Document: ‘#{@document.filename}’"
	rescue ActiveRecord::RecordNotFound
		flash[:notice] = "Could not find a document matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	# document upload form
	def new
		@document = Document.new_doc(params[:document], current_user,
			(params[:private] == '1'))
		@document.valid? if params[:document]
		@page_title = 'New Document'
	end
	
	# document submission
	def create
		@document = Document.new_doc(params[:document], current_user,
			(params[:private] == '1'))
		@document.save!
		flash[:notice] = 'Document was successfully uploaded.'
		redirect_to document_url(@document)
	rescue NoMethodError
		self.new
		render :action=>:new
	rescue ActiveRecord::RecordInvalid
		self.new
		render :action=>:new
	rescue
		flash.now[:notice] = 'An error occurred while trying to upload your new document.'
		self.new
		render :action=>:new
	end
	
	# TODO: updating of document info, such as filename and subfolder
	## EDIT
	#def edit
	#	@document = Document.find_for_user(current_user, params[:id])
	#	if current_user.admin? or @document.user == current_user
	#		@page_title = "Edit ‘#{@document.filename}’"
	#	else
	#		flash[:notice] = "You do not have permission to edit the requested document (‘#{params[:id]}’)."
	#		redirect_to document_path(@document)
	#		@document = nil
	#	end
	#rescue ActiveRecord::RecordNotFound
	#	flash[:notice] = "Could not find a document matching the requested id (‘#{params[:id]}’)."
	#	redirect_to :action=>'index'
	#end
	#
	## UPDATE
	#def update
	#	self.edit
	#	if response.redirected_to
	#		# can’t update - was caught in edit
	#	else
	#		debugger
	#		unless params[:document][:filename].nil?
	#			@document.change_filename(params[:document][:filename])
	#		end
	#		unless params[:document][:subfolder].nil?
	#			@document.change_subfolder(params[:document][:subfolder])
	#		end
	#		if @document.save
	#			flash[:notice] = "Updated information for #{@document.filename}."
	#			redirect_to document_path(@document)
	#		else
	#			# failed to save, back to edit form
	#			render :action=>:edit
	#		end
	#	end
	#end
	
	# DESTROY / DELETE
	def destroy
		@document = Document.find_for_user(current_user, params[:id])
		if current_user.admin? or @document.user == current_user
			@document.destroy
			flash[:notice] = "The document ‘#{@document.filename}’ has been permanently removed."
			redirect_to documents_path
		else
			flash[:notice] = "You do not have permission to modify the requested document (‘#{params[:id]}’)."
			redirect_to document_path(@document)
			@document = nil
		end
	rescue ActiveRecord::RecordNotFound
		flash[:notice] = "Could not find a document matching the requested id (‘#{params[:id]}’)."
		redirect_to :action=>'index'
	end
	
	
	protected
	
	# shared by all actions
	def setup
		@section = 'documents'
	end
end
