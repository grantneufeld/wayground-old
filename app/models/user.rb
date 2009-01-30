module Wayground
	# Current User does not match the requested User.
	class UserMismatch < Exception; end
	# Current User does not have needed access permission.
	class UserWithoutAccessPermission < Exception; end
end

class User < ActiveRecord::Base
	
	# prevents a user from submitting a crafted form that bypasses activation
	# anything else you want your user to be able to set should be added here.
	attr_accessible :password, :password_confirmation, :email,
		:nickname, :fullname, :subpath, :time_zone, :location, :about,
		# anti-spam fake-fields:
		:login, :url
	
	attr_accessor :password, :password_confirmation	,
		# anti-spam fake-fields:
		:login, :url
	
	# TODO: FUTURE: don’t destroy dependent locations when the location model is changed to allow sharing of location objects.
	has_many :locations, :as=>:locatable, :dependent=>:destroy
	has_many :memberships, :dependent=>:destroy
	has_many :groups, :through=>:memberships, :source=>:group
	has_many :invited_memberships, :class_name=>'Membership',
	 	:foreign_key=>'inviter_id', :dependent=>:destroy
	has_many :blocked_memberships, :class_name=>'Membership',
	 	:foreign_key=>'blocker_id', :dependent=>:nullify
	has_many :events, :dependent=>:nullify
	has_many :rsvps, :dependent=>:destroy
	has_many :weblinks, :as=>:item, :dependent=>:destroy
	
	validates_presence_of :fullname
	validates_presence_of :email, :if=>:email_required
	validates_format_of :email,
		:with=>/\A(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?\z/i,
		:message=>"invalid email", :allow_nil=>true
	validates_format_of :subpath,
		:with=>/\A[A-Za-z]([\w_\-]*\w)?\z/,
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
	
	
	# CLASS METHODS
	
	# standard Wayground class methods for displayable items
	def self.default_include
		nil
	end
	def self.default_order
		'users.nickname, users.id'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:key].blank?
			strs << 'users.nickname like ?'
			vals << "%#{p[:key]}%"
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	# Encrypts some data with the salt.
	def self.encrypt(pass, salt)
		Digest::SHA1.hexdigest("--#{salt}--#{pass}--")
	end
	
	
	# INSTANCE METHODS
	
	# Finds a user login by their email and unencrypted password.
	# Returns the user or nil.
	def self.authenticate(email, pass)
		# append the default email domain if user didn’t enter their full email address
		email += "@#{WAYGROUND['DEFAULT_DOMAIN']}" unless email.match /.*@.*/
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
			self.salt = Digest::SHA1.hexdigest("--#{Time.current.to_s}--#{email}--")
		end
		self.crypted_password = encrypted(password)
	end
	
	def make_activation_code
		self.activation_code = Digest::SHA1.hexdigest(
			Time.current.to_s.split(//).sort_by {rand}.join )
	end
	
	# Activates the user in the database.
	def activate(code)
		if code == activation_code
			self.activated_at = Time.current # .utc
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
	
	
	# root-relative url pointing to the user’s profile page
	def profile_path
		"/people/#{(subpath.blank? ? id : subpath)}"
	end
	
	# ########################################################
	# Remember Me Token
	
	def remember_token?
#		remember_token_expires_at && Time.current.utc < remember_token_expires_at
		remember_token_expires_at && Time.current < remember_token_expires_at
	end

	# These create and unset the fields required for remembering users between browser closes
	def remember_me
		remember_me_for 2.weeks
	end

	def remember_me_for(time)
		remember_me_until time.from_now # .utc
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
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		"#{name_prefix}user"
	end
	def description
		nil
	end
	def link
		profile_path
	end
	def title
		if nickname.blank?
			"User #{self.id}"
		else
			nickname
		end
	end
	def title_prefix
		nil
	end
end
