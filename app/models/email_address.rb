class EmailAddress < ActiveRecord::Base
	attr_accessible :email, :position, :name
	
	#t.belongs_to :user
	#t.integer :position
	#t.string :email
	#t.string :activation_code, :limit=>40
	#t.datetime :activated_at
	#t.boolean :is_blocked
	#t.string :name
	#t.timestamps
	
	belongs_to :user
	has_many :memberships
	
	
	before_create :make_activation_code
	
	
	# VALIDATION
	
	validates_presence_of :email
	validates_format_of :email,
		:with=>/\A(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?\z/i,
		:message=>"invalid email address"
	validates_uniqueness_of :email,
		:case_sensitive=>false
	#validates_uniqueness_of :email,
	#	:scope=>[:user_id],
	#	:allow_blank=>true,
	#	:case_sensitive=>false,
	#	:unless=>Proc.new {|e| e.user.blank?}
	validate :valid_email?
	
	include EmailHelper # email validation
	
	# based on http://lindsaar.net/2008/4/15/tip-6-validating-the-domain-of-an-email-address-with-ruby-on-rails
	def valid_email?
		unless email.blank?
			err = domain_error(domain_of(email))
			errors.add(:email, err) unless err.blank?
		end
	end
	
	
	# CLASS METHODS
	
	# Return an Array of Users that have EmailAddresses matching the email string.
	# require_confirmed: only EmailAddresses that have been confirmed will be included.
	def self.find_users_for_email(email, require_confirmed=false)
		addrs = EmailAddress.find(:all, :conditions=>['email_addresses.email = ?', email])
		users = []
		addrs.each do |addr|
			if !(addr.user.nil?) and (!require_confirmed or addr.is_confirmed?)
				users << addr.user
			end
		end
		users.uniq!
		users
	end
	
	def self.activate!(user, code, e_code)
		if !(user.nil?) and !(code.blank?) and !(e_code.blank?)
			e = self.find_by_activation_code(code)
			raise Wayground::ActivationCodeMismatch if e.nil?
			if code == e.activation_code and e_code == e.encrypt_code
				# strike the email from any other users that have it
				users = User.find_all_by_email(e.email)
				users.each do |u|
					unless u == user
						u.update_attribute('email',
							(u.email_addresses[0] ? u.email_addresses[0].email : nil))
					end
				end
				# activate the email address
				e.activated_at = Time.now
				e.activation_code = nil
				e.user = user
				e.save!
				e
			else
				raise Wayground::ActivationCodeMismatch
			end
		else
			raise Wayground::CannotBeActivated
		end
	end
	
	# standard Wayground class methods for displayable items
	def self.default_include
		[:user]
	end
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'email_addresses.updated_at DESC, ') +
			'email_addresses.email'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# - :item is the Item the message is attached to
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:item].nil?
			strs << 'email_addresses.user_id = ?'
			vals << p[:item].id
		end
		unless p[:key].blank?
			strs << '(email_addresses.email like ? OR email_addresses.name like ?)'
			vals += ["%#{p[:key]}%"] * 2
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	
	# INSTANCE METHODS
	
	def before_save
		# if the email has not been activated, make sure the activation_code is set
		#if self.activated_at.blank? and self.activation_code.blank?
		#	debugger
		#	make_activation_code
		#end
		# if there is a user, set the position
		if !(self.user.nil?) and (self.position.nil? or self.position == 0)
			# omit self from the find
			if self.id and self.id > 0
				conditions = ['email_addresses.id != ?', self.id]
			else
				conditions = 'email_addresses.id IS NOT NULL'
			end
			last_address = user.email_addresses.find(:first,
				:conditions=>conditions,
				:order=>'email_addresses.position DESC')
			if last_address
				self.position = last_address.position.to_i + 1
			else
				self.position = 1
			end
			#write_attribute('position', position)
		end
	end
	
	def make_activation_code
		code = nil
		while code == nil
			code = Digest::SHA1.hexdigest(
				Time.current.to_s.split(//).sort_by {rand}.join )
			# ensure there isn't a matching code already
			code = nil if self.class.find_by_activation_code(code)
		end
		self.activation_code = code
	end
	
	def activated?
		!(self.activated_at.blank?)
	end
	
	def blocked?
		(self.is_blocked and self.is_blocked != 0) ? true : false
	end
	
	# Encrypts the email with the activation code as salt
	def encrypt_code(e=nil)
		User.encrypt((e || self.email), self.activation_code)
	end
	
	def name
		n = read_attribute(:name)
		if n.blank?
			if self.user
				n = self.user.fullname
			else
				n = nil
			end
		end
		n
	end
	
	# assign this EmailAddress to a User (after both have already been created)
	def assign_to_user!(u)
		self.user = u
		self.assign_memberships_to_user!
		save!
		u
	end
	
	# move any Memberships associated with this EmailAddress to the user
	def assign_memberships_to_user!
		if self.user
			self.memberships.each do |membership|
				unless membership.user == self.user
					membership.user = nil
					self.user.memberships << membership
				end	
			end
		end
	end
	
	# an EmailAddress is considered confirmed only if there is a user, and no activation_code
	def is_confirmed?
		!(self.user.nil? or self.activated_at.blank?)
	end
	
	def to_s
		if blocked?
			nil
		elsif self.name.blank?
			self.email
		elsif self.name.match(/[^A-Za-z0-9_ ]/)
			# name has to be wrapped in quotes if it includes anything but the most basic chars
			"\"#{self.name}\" <#{self.email}>"
		else
			"#{self.name} <#{self.email}>"
		end
	end
	
	# standard Wayground instance methods for displayable items
	def css_class(prefix='')
		"#{prefix}contact"
	end
	def description
		nil
	end
	def link
		"/email_addresses/#{self.id}"
	end
	def title
		if self.name.blank?
			"Contact #{self.id}"
		else
			self.name
		end
	end
	def title_prefix
		nil
	end
	
	# required instance methods for Contactable items
	# email returned by attribute
	def email_addresses
		return [self]
	end
	def locations
		return []
	end
	# name returned by attribute
end
