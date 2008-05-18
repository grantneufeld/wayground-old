class User < ActiveRecord::Base
	
	# prevents a user from submitting a crafted form that bypasses activation
	# anything else you want your user to be able to set should be added here.
	attr_accessible :password, :password_confirmation, :email,
		:nickname, :fullname, :subpath, :location, :about
	
	attr_accessor :password, :password_confirmation
	
	validates_presence_of :fullname
	validates_presence_of :email, :if=>:email_required
	validates_format_of :email,
		:with=>/\A(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?\z/i,
		:message=>"invalid email", :allow_nil=>true
	validates_format_of :subpath,
		:with=>/\A([\w_\-]*\w[\w_\-]*)*\z/,
		:allow_nil=>true,
		:message=>'invalid url subpath - only lowercase letters, numbers, dashes ‘-’ and underscores ‘_’ are permitted, and there must be at least one letter'
	validates_uniqueness_of :subpath, :email, :allow_nil=>true,
		:case_sensitive=>false #, :nickname
	validates_presence_of :password_confirmation, :if=>:password_changed?
	validates_confirmation_of :password
	validates_length_of :password, :minimum=>7, :allow_nil=>true
	validate :valid_email?
	
	before_save :encrypt_password
	before_create :make_activation_code
	
	
	include EmailHelper # email validation
	
	# based on http://lindsaar.net/2008/4/15/tip-6-validating-the-domain-of-an-email-address-with-ruby-on-rails
	def valid_email?
		unless email.blank?
			err = domain_error(domain_of(email))
			errors.add(:email, err) unless err.blank?
		end
	end
	
	
	# Encrypts some data with the salt.
	def self.encrypt(pass, salt)
		Digest::SHA1.hexdigest("--#{salt}--#{pass}--")
	end
	
	# Finds a user login by their email and unencrypted password.
	# Returns the user or nil.
	def self.authenticate(email, pass)
		u = find(:first, :conditions=>['email = ? AND crypted_password IS NOT NULL', email])
			#' and activated_at IS NOT NULL', email]) # need to get the salt
		u && u.password_matches?(pass) ? u : nil
	end
	
	def password_changed?
		!(password.blank?)
	end
	
	def email_required
		@email_required || false
	end|
	def email_required=(r)
		@email_required = r
	end
	
	# Encrypts the password with the user salt
	def encrypted(pass)
		self.class.encrypt(pass, salt)
	end
	def password_matches?(pass)
		crypted_password == encrypted(pass)
	end
	
	# before filter
	def encrypt_password
		return if password.blank?
		if new_record?
			self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--")
		end
		self.crypted_password = encrypted(password)
	end
	
	def make_activation_code
		self.activation_code = Digest::SHA1.hexdigest(
			Time.now.to_s.split(//).sort_by {rand}.join )
	end
	
	# Activates the user in the database.
	def activate(code)
		if code == activation_code
			self.activated_at = Time.now.utc
			self.activation_code = nil
			save!
			@activated = true
		else
			false
		end
	end
	
	def activated?
		!(activated_at.blank?)
	end
	
	def admin?
		admin
	end
	def staff?
		staff
	end
	
	def change_password(old_pass,new_pass)
		if password_matches?(old_pass)
			self.password = new_pass
			encrypt_password
			self.password = nil
			save!
			self
		else
			nil
		end
	end
	
	def display_name
		if nickname.blank?
			"User #{self.id}"
		else
			nickname
		end
	end
	
	# ########################################################
	# Remember Me Token
	#
	# TODO: Add unit tests for use of the remember me token
	
	def remember_token?
		remember_token_expires_at && Time.now.utc < remember_token_expires_at
	end

	# These create and unset the fields required for remembering users between browser closes
	def remember_me
		remember_me_for 2.weeks
	end

	def remember_me_for(time)
		remember_me_until time.from_now.utc
	end

	def remember_me_until(time)
		self.remember_token_expires_at = time
		self.remember_token = encrypted("#{email}--#{remember_token_expires_at}")
		save(false)
	end
	
	# wipe user’s remember_token
	def forget_me
		self.remember_token_expires_at = nil
		self.remember_token = nil
		save(false)
	end
	
end
