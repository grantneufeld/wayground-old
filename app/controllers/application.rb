# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
	helper :all # include all helpers, all the time
	# make the current_user method available to views:
	helper_method :current_user	
	# See ActionController::RequestForgeryProtection for details
	# Uncomment the :secret if you're not using the cookie session store
	protect_from_forgery :secret=>'44231f4cfece88f5120e19b6be4974f9'
	
	# See ActionController::Base for details 
	# Uncomment this to filter the contents of submitted sensitive data parameters
	# from your application log (in this case, all fields with names like "password"). 
	filter_parameter_logging :password, :password_confirm
	
	# Timezone code based on:
	# http://mad.ly/2008/04/09/rails-21-time-zone-support-an-overview/
	before_filter :set_time_zone

	# TODO: TESTS HAVE NOT BEEN WRITTEN FOR ANY OF THE FOLLOWING CODE!
	
	
	protected
	
	# ########################################################
	# USER ACCESS
	
	def really_logged_in?
		!(current_user.nil?)
	end
	# Accesses the current user for the session.
	def current_user
		if @current_user_already_checked
			@current_user
		else	
			@current_user_already_checked = true
			@current_user = (login_from_session || login_from_basic_auth || login_from_cookie)
		end
	end
	# Store the given user id in the session.
	def current_user=(new_user)
		session[:user] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
		@current_user = new_user
	end
	
	# before filters for actions requiring user to have adequate access level
	def login_required
		!(current_user.nil?) || access_denied
	end
	def activation_required
		(!(current_user.nil?) && current_user.activated?) || access_denied
	end
	def admin_required
		(!(current_user.nil?) && current_user.admin) || access_denied
	end
	def staff_required
		(!(current_user.nil?) && current_user.staff) || access_denied
	end
	
	# Redirect as appropriate when an access request fails.
	#
	# The default action is to redirect to the login screen.
	#
	# Override this method in your controllers if you want to have special
	# behavior in case the user is not authorized
	# to access the requested action.  For example, a popup window might
	# simply close itself.
	def access_denied
		respond_to do |format|
			format.html do
				store_location
				flash[:warning] = 'You do not have permission to access the requested action. Please login as a user with sufficient permission.'
				if current_user
					redirect_to account_users_path
				else
					redirect_to login_path
				end
			end
			format.xml do
				# The old way of doing it:
				#headers["Status"]           = "Unauthorized"
				#headers["WWW-Authenticate"] = %(Basic realm="Web Password")
				#render :text => "Could't authenticate you", :status => '401 Unauthorized'
				request_http_basic_authentication 'Web Password'
			end
		end
		false
	end
	
	# Store the URI of the current request in the session.
	# We can return to this location by calling #redirect_back_or_default.
	def store_location
		session[:return_to] = request.request_uri
	end
	
	# Redirect to the URI stored by the most recent store_location call or
	# to the passed default.
	def redirect_back_or_default(default='/')
		redirect_to(session[:return_to] || default)
		session[:return_to] = nil
	end
	
	
	private
	
	# ########################################################
	# USER ACCESS
	
	# Called from #current_user.
	# Attempt to login by the user id stored in the session.
	def login_from_session
		self.current_user = User.find(session[:user]) if session[:user]
	end

	# Called from #current_user.
	# Attempt to login by basic authentication information.
	def login_from_basic_auth
		#username, passwd = get_auth_data
		#self.current_user = User.authenticate(username, passwd) if username && passwd
		authenticate_with_http_basic do |username, password|
			self.current_user = User.authenticate(username, password)
		end
	end

	# Called from #current_user.
	# Attempt to login by an expiring token in the cookie.
	def login_from_cookie
		#user = cookies && cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
		user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
		if user && user.remember_token?
			user.remember_me
			if cookies
				cookies[:auth_token] = {:value=>user.remember_token,
					:expires=>user.remember_token_expires_at }
			end
			self.current_user = user
		end
	end

	def set_time_zone
		Time.zone = current_user.time_zone if current_user
	end
	
end
