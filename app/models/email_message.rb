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
	validates_format_of :from, :with=>/\A(("[\w' _\-]*"|[A-Za-z0-9 ]+) )?<?(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?>?\z/i,
		:message=>"must be a valid email address, optionally wrapped in angle-brackets with a quote-wrapped name in front"
	validates_presence_of :content_type
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
			strs << 'email_messages.subject like ? OR email_messages.to like ? OR email_messages.from like ?'
			vals += ["%#{p[:key]}%"] * 3
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	
	# INSTANCE METHODS
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		"#{name_prefix}email"
	end
	def description
		nil
	end
	def link
		self
	end
	def title
		subject
	end
	def title_prefix
		updated_at.to_s(:tight)
	end
end
