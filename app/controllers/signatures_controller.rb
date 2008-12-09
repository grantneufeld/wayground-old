class SignaturesController < ApplicationController
	before_filter :set_petition
	
	# TODO: mostly everything
	
	def create
		@signature = @petition.sign(params[:signature], current_user)
		flash[:notice] = "Thanks for adding your signature! A confirmation email has been sent to you at #{@signature.email} with instructions to confirm your signature so it can be added to the petition. Please look for a message from: #{(WAYGROUND['SENDER'].gsub(/[><]/){|x|{'>'=>'&gt;','<'=>'&lt;'}[x]})}."
		redirect_to petition_signature_url(@petition, @signature)
	rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
		flash[:error] = 'Your signature could not be saved. Please check your information in the form to ensure you have filled in all required fields correctly.'
		render :controller=>'petitions', :action=>'show', :id=>@petition
	rescue Wayground::NotifierSendFailure
		flash[:error] = "Your signature was received, but there was an error when trying to send an email confirmation. Please contact the website administrator about this problem. #{WAYGROUND['EMAIL']}"
		redirect_to petition_signature_url(@petition, @signature)
	end
	
	def confirm
		@signature = Signature.find(params[:id])
		@signature.confirm(params[:code], current_user)
		redirect_to petition_signature_url(@petition, @signature)
	rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
		flash[:error] = 'Failed to confirm the signature on the petition.'
		redirect_to petition_url(@petition)
	rescue Wayground::UserMismatch
		store_location
		if current_user.nil?
			flash[:warning] = 'You will have to sign-in first to confirm your signature on the petition.'
			redirect_to login_url
		else
			flash[:error] = 'You are not signed-in as the user who was signed-in when the signature was added. Please logout and then sign-in as that user to be able to confirm the signature.'
			redirect_to user_url(current_user)
		end
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
	
	protected
	
	def set_petition
		@section = 'petitions'
		@petition = Petition.find(params[:petition_id])
	rescue ActiveRecord::RecordNotFound
		missing
	end
	
end
