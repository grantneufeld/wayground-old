class PhoneMessage < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :contact_id, :status, :source, :category, :phone, :content
	
	belongs_to :user
	belongs_to :owner, :class_name=>'User'
	belongs_to :contact, :class_name=>'User'

	has_many :recipients, :dependent=>:nullify
	has_many :attachments, :dependent=>:nullify
	
	validates_presence_of :user
	validates_presence_of :owner
	validates_presence_of :status
	validates_inclusion_of :status, :in=>%w( open read closed )
	validates_presence_of :source
	validates_inclusion_of :source, :in=>%w( phone email fax walk-in )
	
	
	# CLASS METHODS

	# standard Wayground class methods for displayable items
	def self.default_include
		[:owner, :contact]
	end
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'phone_messages.updated_at DESC, ') +
			'phone_messages.created_at DESC'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# - :owner is the User who the message is assigned to
	# - :contact is the User the message is from
	# - :status ( open read closed )
	# - :source ( phone email fax walk-in )
	# - :category
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:owner].nil?
			strs << 'phone_messages.owner_id = ?'
			vals << p[:owner].id
		end
		unless p[:contact].nil?
			strs << 'phone_messages.contact_id = ?'
			vals << p[:contact].id
		end
		unless p[:status].nil?
			strs << 'phone_messages.status = ?'
			vals << p[:status]
		end
		unless p[:source].nil?
			strs << 'phone_messages.source = ?'
			vals << p[:source]
		end
		unless p[:category].nil?
			strs << 'phone_messages.category = ?'
			vals << p[:category]
		end
		unless p[:key].blank?
			strs << 'phone_messages.category like ? OR phone_messages.phone like ? OR phone_messages.content like ?'
			vals += ["%#{p[:key]}%"] * 3
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	
	# INSTANCE METHODS
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		"#{name_prefix}phonemessage"
	end
	def description
		"#{status}: #{category}"
	end
	def link
		self
	end
	def title
		"For #{owner.nickname}; From #{phone}"
		#(
		#	phone.blank? ?
		#		(contact.nil? ? '?' : contact.fullname)
		#	: phone)
	end
	def title_prefix
		created_at.to_s(:tight)
	end
end
