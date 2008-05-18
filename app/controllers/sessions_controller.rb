class SessionsController < ApplicationController
	
	# user login form
	def new
		if current_user
			redirect_back_or_default(account_users_path)
		else
			@page_title = 'Login'
		end
	end
	
	# user login
	def create
		self.current_user = User.authenticate(params[:email], params[:password])
		if current_user
			if params[:remember_me] == '1'
				self.current_user.remember_me
				cookies['auth_token'] = {:value=>self.current_user.remember_token,
					:expires=>self.current_user.remember_token_expires_at}
			end
			current_user.update_attributes :login_at=>Time.now
			if current_user.activated?
				flash[:notice] = 'Logged in successfully'
			else
				flash[:warning] = 'Logged in successfully, but you still need to confirm your registration. Please check your email for the confirmation message.'
			end
			redirect_back_or_default(account_users_path)
		else
			flash.now[:error] = 'Login failed. Please reenter your email and password.'
			render :action=>'new'
		end
	end
	
	# user logout
	def destroy
		self.current_user.forget_me if current_user
		cookies.delete 'auth_token'
		reset_session
		flash[:notice] = 'You have been logged out.'
		redirect_back_or_default login_path
	end
end
