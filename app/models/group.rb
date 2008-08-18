# TODO: use subpath as the id for route path lookups instead of the integer id

class Group < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :is_public, :is_visible, :is_invite_only,
		:is_members_visible, :is_no_unsubscribe, :subpath, :name, :url,
		:description, :welcome
	
	validates_presence_of :subpath
	validates_presence_of :name
	
	validates_format_of :subpath,
		:with=>/\A[A-Za-z][\w\-]*\z/,
		:message=>'must begin with a letter and only consist of letters, numbers and/or dashes (a-z, 0-9, -)'
	validates_format_of :url, :allow_nil=>true,
		:with=>/\Ahttps?:\/\/[^ \t\r\n]+\z/,
		:message=>'must be a valid URL (starting with ‘http://’)'
	
	validates_exclusion_of :subpath,
		:in=>%w(index show list new create edit update destroy delete search about addresses admin archive archives attachments bin blogs boards calendar calendars campaigns candidates categories chunks classified classifieds comments contacts description docs documents elections emails events files forums functions groups images layouts levels links listings locations media members memberships messages news offices pages parties paths petitions photos pics pictures podcasts policies polls ratings replies resources rss rsvp rsvps schedules signatures surveys tag tags topics trash users videos vids votes weblinks welcome wiki),
		:message=>"the subpath %s is reserved and cannot be used for your group"
	
	# subpath is globally unique for groups - even if the group has a parent
	# part of this is that the subpath may be used in future to define an
	# email address for the group (e.g., group-subpath@groups.wayground.ca)
	validates_uniqueness_of :subpath,
		:message=>'that subpath is already in use by another group'
	validates_uniqueness_of :name,
		:message=>'that name is already in use by another group'
	
	belongs_to :creator, :class_name=>'User'
	belongs_to :owner, :class_name=>'User'
	
	belongs_to :parent, :class_name=>'Group'
	has_many :children, :class_name=>'Group', :foreign_key=>'parent_id',
		:order=>'groups.name'
	
	has_many :memberships, :order=>'memberships.position', :dependent=>:destroy
	has_many :members, :through=>:memberships, :source=>:user
	
	
	# CLASS METHODS
	
	# return a conditions string for find.
	# u is the current_user to use to determine access to private groups. [currently ignored]
	# key is a search restriction key
	def self.search_conditions(only_visible=false, u=nil, key=nil)
		constraints = []
		values = []
		if only_visible or u.nil?
			# only public or no user
			constraints << '(groups.is_visible = 1)'
		end
		unless key.blank?
			constraints << "(groups.name LIKE ? OR groups.subpath LIKE ? OR groups.description LIKE ?)"
			values += ["%#{key}%"] * 3
		end
		[constraints.join(' AND ')] + values
	end
	
	# override the default find to allow first argument to be a string -
	# the subpath
	def self.find(*args)
		if args[0].is_a?(Symbol) or args[0].to_i > 0 or !(args[0].is_a?(String))
			super(*args)
		else
			# first argument is a string (subpath)
			id = args[0]
			args[0] = :first
			options = args.last.is_a?(Hash) ? args.pop : nil
			if options.nil? or options[:conditions].nil?
				# no conditions set, so set to our security conditions
				options ||= {}
				options[:conditions] =
					["(groups.subpath = :subpath)",
					{:subpath=>id}]
			elsif options[:conditions].is_a? String
				# conditions are just a raw SQL sub-string, so add our conditions
				options[:conditions] = ["(#{options[:conditions]}) AND (groups.subpath = :subpath)",
					{:subpath=>id}]
			elsif options[:conditions].is_a? Array	
				# conditions are an array so mix-in our conditions
				if options[:conditions][1].class == Hash
					# the conditions array is using a parameter hash,
					# so mix-in our conditions as hash values
					options[:conditions][0] = "(#{options[:conditions][0]}) AND (groups.subpath = :subpath)"
					options[:conditions][1].merge!({:subpath=>id})
				else
					# conditions array is using '?' parameters,
					# so append our conditions
					options[:conditions][0] =
						"(#{options[:conditions][0]}) AND (groups.subpath = ?)"
					options[:conditions] << id
				end
			else
				raise Exception.new("class of supplied conditions is not recognized")
			end
			args << options
			group = super(*args)
			raise ActiveRecord::RecordNotFound if group.nil?
			group
		end
	end
	
	
	# INSTANCE METHODS
	
	# use the group’s subpath instead of the id
	def to_param
		subpath
	end
	
	# Returns an Array of email address Strings for members of the group.
	def email_addresses(only_validated = false)
		[]
	end
	# Returns a Hash of email addresses with details for members of the group.
	def email_addresses_with_details(only_validated = false)
		# {'email@address'=>{:name=>'member name'},...}
		{}
	end
	
end
