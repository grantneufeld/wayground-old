class EmailMessage < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :status, :from, :to, :subject, :content_type, :content
	
	belongs_to :user
	# item model will typically be Group
	belongs_to :item, :polymorphic=>true

	has_many :recipients, :dependent=>:nullify
	has_many :attachments, :dependent=>:nullify
	
	validates_presence_of :user
	validates_presence_of :status
	validates_inclusion_of :status, :in=>%w( draft sent )
	validates_presence_of :from
	validates_format_of :from, :with=>/\A(("[\w'. _\-]*"|[A-Za-z0-9_ ]+) )?<?(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?>?\z/i,
		:message=>"must be a valid email address, optionally wrapped in angle-brackets with a quote-wrapped name in front"
	validates_inclusion_of :content_type, :in=>%w( text/plain text/html ),
		:message=>"may only be plain text or html"
	
	
	# CLASS METHODS

	# standard Wayground class methods for displayable items
	def self.default_include
		[:user, :item]
	end
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'email_messages.updated_at DESC, ') +
			'email_messages.subject'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# - :sender is the User who sent the message
	# - :item is the Item the message is attached to
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:sender].nil?
			strs << 'email_messages.user_id = ?'
			vals << p[:sender].id
		end
		unless p[:item].nil?
			strs << 'email_messages.item_id = ? AND email_messages.item_type = ?'
			vals += [p[:item].id, p[:item].class.name]
		end
		unless p[:key].blank?
			strs << '(email_messages.subject like ? OR email_messages.to like ? OR email_messages.from like ?)'
			vals += ["%#{p[:key]}%"] * 3
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	
	# INSTANCE METHODS
	
	def before_validation
		if self.content_type.nil? or read_attribute('content_type').nil?
			self.content_type = 'text/plain'
		end
	end
	
	def has_recipient_email(email)
		addrs = EmailAddress.find_all_by_email(email)
		addrs.each do |e|
			r = self.recipients.find_by_email_address_id(e.id)
			if r
				return r
			end
		end
		return nil
	end
	
	# e - EmailAddress
	def add_recipient(e)
		if has_recipient_email(e.email)
			nil
		else
			recipient = Recipient.new()
			recipient.email_address = e
			self.recipients << recipient
			self.save!
			recipient
		end
	end
	
	# should only be called once - by deliver! - to ensure no duplicates
	# or recipients that were removed
	def initialize_recipients
		if self.recipients.nil? or self.recipients.size == 0
			# make sure the email_message has been saved so new Recipients will save
			self.save!
			email_addrs = []
			if self.item
				# add item’s email recipients to recipients
				email_addrs = self.item.email_addresses
			else
				# add custom “to:” to recipients
				r_strs = []
				self.to.scan(/\A(("([\w'. _\-]*)"|[A-Za-z0-9_ ]+) )?<?((\w[\w_\.\+\-]*)@(?:\w[\w\-]*\.)+[a-z]{2,})?>?\z/i) {|a, name, clipped_name, email, email_first_part, b|
					r_strs << [(clipped_name.blank? ? name : clipped_name),
						email]
				}
				r_strs.each do |name, email|
					e = EmailAddress.find_by_email(email)
					if e.nil?
						e = EmailAddress.new(:email=>email, :name=>name)
						e.save!
					end
					email_addrs << e
				end
			end
			@blocked ||= []
			email_addrs.each do |e|
				if e.blocked?
					# don't include blocked addresses
					@blocked << e
				else
					add_recipient(e)
				end
			end
			if self.self_copy
				# add user to recipients
				add_recipient(self.user.email_addresses[0])
			end
		end
	end
	
	def deliver!
		sent_at = Time.current
		initialize_recipients
		failed_recipients = []
		self.recipients.each do |recipient|
			begin
				Notifier::deliver_email_message({:recipient=>recipient, :from=>self.from,
					:subject=>self.subject, #:reply_to=>nil,
					:content=>self.content, :sent_at=>sent_at})
				recipient.sent_at = sent_at
			rescue Net::SMTPFatalError => smtp_err	
				recipient.sent_at = nil
				recipient.last_send_attempt_at = sent_at
				failed_recipients << "#{recipient}: #{smtp_err}"
			end
			recipient.save!
		end
		if failed_recipients.size > 0
			raise Wayground::DeliveryFailure.new(failed_recipients.join("\n"))
		end
		self.status = 'sent'
		save!
	end
	
	# a list of EmailAddresses of any recipients who were blocked
	def blocked
		@blocked || []
	end
	
	def self_copy
		@self_copy || false
	end
	def self_copy=(s)
		@self_copy = !(s.blank?)
	end
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		"#{name_prefix}#{self.status == 'sent' ? 'emailsent' : 'email'}"
	end
	def description
		nil
	end
	def link
		self
	end
	def title
		self.subject
	end
	def title_prefix
		self.updated_at.to_s(:tight)
	end
end
