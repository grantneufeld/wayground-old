class EmailAddress < ActiveRecord::Base
	attr_accessible :email, :position, :name
	
	#t.belongs_to :user
	#t.integer :position
	#t.string :email
	#t.string :activation_code, :limit=>40
	#t.datetime :activated_at
	#t.string :name
	#t.timestamps
	
	belongs_to :user
	has_many :memberships
	
	
	# VALIDATION
	
	validates_presence_of :email
	validates_format_of :email,
		:with=>/\A(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?\z/i,
		:message=>"invalid email address"
	validates_uniqueness_of :email,
		:scope=>[:user_id],
		:allow_blank=>true,
		:case_sensitive=>false,
		:unless=>Proc.new {|e| e.user.blank?}
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
	
	
	# INSTANCE METHODS
	
	def before_save
		# if there is a user, and the email has not been activated,
		# make sure the activation_code is set
		if !(user.nil?)
			if activated_at.blank? and activation_code.blank?
				make_activation_code
			end
			if position.nil? or position == 0
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
					position = last_address.position.to_i + 1
				else
					position = 1
				end
				write_attribute('position', position)
			end
		end
	end
	
	def make_activation_code
		self.activation_code = Digest::SHA1.hexdigest(
			Time.current.to_s.split(//).sort_by {rand}.join )
	end
	
	def activate!(code)
		if !(code.blank?)
			if code == (activation_code || read_attribute('activation_code'))
				activated_at = Time.now
				write_attribute('activated_at', activated_at)
				activation_code = nil
				write_attribute('activation_code', activation_code)
			else
				raise Wayground::ActivationCodeMismatch
			end
		else
			raise Wayground::CannotBeActivated
		end
	end
	
	# assign this EmailAddress to a User (after both have already been created)
	def assign_to_user!(u)
		if u.email.blank?
			# ensure activation check is in place if needed
			if activated_at.blank? and activation_code.blank?
				# this email has not been activated
				make_activation_code
			end
			u.email = email
			u.activation_code = activation_code
			u.activated_at = activated_at
			u.save!
			# since the User now has this email address,
			# we might as well get rid of this redundant record
			move_memberships_to_user!
			self.destroy
		else
			user = u
			save!
		end
		u
	end
	
	# move any Memberships associated with this EmailAddress to the user
	def move_memberships_to_user!
		if user
			memberships.each do |membership|
				unless membership.user
					membership.user = user
				end	
				membership.email_address = nil
				membership.save!
			end
		end
	end
	
	# an EmailAddress is considered confirmed only if there is a user, and no activation_code
	def is_confirmed?
		!(user.nil? or activated_at.blank?)
	end
	
end
