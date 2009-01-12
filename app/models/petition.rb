class Petition < ActiveRecord::Base
	attr_accessible :subpath, :start_at, :end_at, :public_signatures,
		:allow_comments, :goal, :title, :description, :custom_field_label,
		:country_restrict, :province_restrict, :city_restrict,
		:restriction_description, :content, :thanks_message
	
	belongs_to :user
	has_many :signatures, :order=>'signatures.id', :dependent=>:delete_all
	has_many :confirmed_signatures, :class_name=>'Signature',
		:foreign_key=>'petition_id',
		:conditions=>'signatures.confirmed_at IS NOT NULL',
		:order=>'signatures.position'
	
	#validates_presence_of :subpath # covered by validates_format_of below
	validates_presence_of :user
	validates_presence_of :title
	validates_presence_of :content
	validates_exclusion_of :subpath, :in=>WAYGROUND['RESERVED_SUBPATHS'],
		:message=>"the subpath %s is reserved and cannot be used for your petition"
	validates_format_of :subpath,
		:with=>/\A[A-Za-z][\w\-]*\z/,
		:message=>'must begin with a letter and only consist of letters, numbers and/or dashes (a-z, 0-9, -)'
	validates_uniqueness_of :subpath,
		:message=>'that subpath is already in use by another petition'
	validates_uniqueness_of :title,
		:message=>'that title is already in use by another petition'
	
	
	# CLASS METHODS

	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :only_active restricts to only items that have started and not ended
	# - :u is the current_user to use to determine access to private items.
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		if p[:only_active]
			# only petitions that are currently active
			strs << '((petitions.start_at IS NULL OR petitions.start_at <= NOW()) AND (petitions.end_at IS NULL OR petitions.end_at > NOW()))'
		end
		unless p[:key].blank?
			strs << "(petitions.title LIKE ? OR petitions.subpath LIKE ? OR petitions.description LIKE ?)"
			vals += ["%#{p[:key]}%"] * 3
		end
		[strs.join(' AND ')] + vals
	end
	def self.default_order
		'petitions.title'
	end
	def self.default_include
		nil
	end
	
	
	# INSTANCE METHODS
	
	# Generates and returns a new Signature on the Petition.
	# - attributes is a Hash of parameters like would be passed in to Signature.new.
	# - signer is the User signing (if logged in).
	def sign(attributes, signer=nil)
		# TODO: if user is not logged in, check that the signature email does not belong to a registered user. If it does, don’t sign, but prompt the user to login.
		s = signatures.build(attributes)
		s.user = signer
		# set the position
		s.position = self.signature_count + 1
		self.signature_count += 1
		# setup confirmation_code
		s.confirmation_code = Digest::SHA1.hexdigest(
			"-#{Time.current.to_s}-#{s.email}-#{s.name}-")
		s.save!
		# send email confirmation
		unless Notifier.deliver_signature_confirmation(self, s, signer)
			raise Wayground::NotifierSendFailure
		end
		
		s
	end
	
end
