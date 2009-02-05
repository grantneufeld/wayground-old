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
	validates_uniqueness_of :email, :nickname, :subpath, :allow_blank=>true,
		:case_sensitive=>false
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
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'users.updated_at DESC, ') +
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
	
	# Finds a user login by their email and unencrypted password.
	# Returns the user or nil.
	def self.authenticate(email, pass)
		# append the default email domain if user didn’t enter their full email address
		email += "@#{WAYGROUND['DEFAULT_DOMAIN']}" unless email.match /.*@.*/
		u = find(:first, :conditions=>['email = ? AND crypted_password IS NOT NULL', email])
			#' and activated_at IS NOT NULL', email]) # need to get the salt
		u && u.password_matches?(pass) ? u : nil
	end
	
	
	# Try to figure out which User, in an array of Users, is closest to the given name.
	def self.find_best_match_for(name, users)
		# When checking for name matches, convert to lower-case and strip
		# all non-alpha characters.
		name_parts = name.scan(/[A-Za-z]+/)
		name_parts.collect! {|n| n.downcase}
		compressed_name = name_parts.join('')
		scores = []
		users.each do |u|
			score = {:u=>u, :score=>0, :missing=>0, :match=>false}
			if u.fullname == name
				# exact match
				score[:match] = :exact
			else
				uname_parts = u.fullname.scan(/[A-Za-z]+/)
				uname = uname_parts.join('').downcase
				if uname == compressed_name
					# all alpha characters match in sequence
					score[:match] = :alpha
				else
					# TODO: come up with a better way to find possible matching/similar names
					# check each part of the name to see if it shows up
					name_parts.each do |name_part|
						if uname.match(name_part)
							score[:score] += 1
						else
							score[:missing] += 1
						end
					end
					uname_parts.each do |uname_part|
						unless compressed_name.match(uname_part)
							score[:missing] += 1
						end
					end
				end
			end
			scores << score
		end
		# rant the 
		scores.sort! {|a,b|
			# exact matchs come first
			if a[:match] == :exact and b[:match] != :exact
				-1
			elsif a[:match] != :exact and b[:match] == :exact
				1
			# alpha matches come first
			elsif a[:match] == :alpha and b[:match] != :alpha
				-1
    		elsif a[:match] != :alpha and b[:match] == :alpha
    			1
			# higher scores come first
			elsif a[:score] < b[:score]
				1
			elsif a[:score] > b[:score]
				-1
			# lower missing come first
			elsif a[:missing] > b[:missing]
				1
			elsif a[:missing] < b[:missing]
				-1
			# equal score
			else
				0
			end
		}
		if scores[0]
			scores[0][:u]
		else
			nil
		end
	end
	# Returns a user matching the email address (or with a Location(s) matching it).
	# attrs is a hash:
	# - :email [required] the exact email address to match
	# - :name [optional] a user name to use in attempting to find a match if multiple Locations match the email
	def self.find_matching_email(attrs)
		raise Exception.new('missing :email in passed in parameters') if attrs[:email].blank?
		# determine if there’s an existing user matching the email
		user = User.find(:first,
			:conditions=>User.search_conditions({}, ['users.email = ?'], [attrs[:email]]))
		unless user
			# determine if there are any Locations (for Users) matching the email
			addrs = EmailAddress.find(:all, :conditions=>[
				'email_addresses.email = ?', attrs[:email]])
			users = addrs.collect { |addr| addr.user }
			users.uniq!
			if users.size == 1
				# just one user with the email address
				user = users[0]
			elsif users.size > 1
				# there is more than one user to choose from :-(
				if attrs[:name].blank?
					# no way to narrow down the choices, so just go with the first user
					# TODO: provide a way for user to choose between options
					user = users[0]
				else
					user = User.find_best_match_for(attrs[:name], users)
				end
			end
		end
		user
	end
	# Returns an array of Users matching the email address (or with EmailAddress(es) matching it).
	# attrs is a hash:
	# email is the exact email address to match
	def self.find_all_matching_email(email)
		users = User.find(:all,
			:conditions=>User.search_conditions({}, ['users.email = ?'], [email]))
		# determine if there are any EmailAddresses matching the email
		addrs = EmailAddress.find(:all, :conditions=>[
			'email_addresses.email = ?', email])
		addrs.each do |addr|
			users << addr.user
		end
		users.uniq!
		users
	end
	
	
	# INSTANCE METHODS
	
	def password_changed?
		!(password.blank?)
	end
	
	# Used by controllers to flag email as required when creating/registering a new user
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
	
	def display_name_for_admin(is_admin)
		if is_admin
			fullname
		else
			title
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
