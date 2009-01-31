class Signature < ActiveRecord::Base
	attr_accessible :is_public, :allow_followup, :name, :email,
		:phone, :address, :city, :province, :country, :postal_code,
		:custom_field, :comment
	
	belongs_to :petition
	belongs_to :user
	
	validates_presence_of :petition
	validates_presence_of :name
	validates_presence_of :email
	validates_format_of :email,
		:with=>/\A(\w[\w_\.\+\-]*@(?:\w[\w\-]*\.)+[a-z]{2,})?\z/i,
		:message=>"invalid email", :allow_nil=>true
	validates_uniqueness_of :user_id, :scope=>:petition_id,
		:message=>'you have already signed this petition',
		:if=>Proc.new {|sig| !(sig.user.nil?) }
	validates_uniqueness_of :email, :scope=>:petition_id,
		:message=>'invalid signature'
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
	
	# standard Wayground class methods for displayable items
	def self.default_include
		nil
	end
	def self.default_order
		'signatures.id'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :only_confirmed restricts to only signatures that have been confirmed
	# - :u is the current_user to use to determine access to private items.
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		if p[:only_confirmed]
			# only signatures that have been confirmed
			strs << 'signatures.confirmed_at IS NOT NULL'
		end
		unless p[:key].blank?
			strs << 'signatures.name LIKE ?'
			vals << "%#{p[:key]}%"
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	def self.confirm(confirmation_code, user=nil)
		s = find(:first, :conditions=>[
				'signatures.confirmation_code = ? AND signatures.confirmed_at IS NULL',
				confirmation_code],
			:include=>[:petition, :user])
		if s.nil?
			raise ActiveRecord::RecordNotFound
		elsif s.user.nil? and !(user.nil?)
			# user wasn’t set when signature was created, so set now
			s.user = user
		elsif s.user == user
			# current user matches signing user
		else
			# throw an error because current user isn’t the user that signed
			raise Wayground::UserMismatch
		end
		if s.confirmed_at.nil?
			s.confirmed_at = Time.now
		end
		s.save!
		s
	end
	
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		"#{name_prefix}signature"
	end
	def description
		nil
	end
	def link
		self
	end
	def title
		name
	end
	def title_prefix
		(position && (position > 0)) ? "#{position}." : nil
	end
end
