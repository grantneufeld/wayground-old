class Group < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :is_public, :is_visible, :is_invite_only,
		:is_members_visible, :is_no_unsubscribe, :subpath, :name, :url,
		:description, :welcome
	
	validates_presence_of :owner
	validates_presence_of :creator
	validates_presence_of :subpath
	validates_presence_of :name
	
	validates_format_of :subpath,
		:with=>/\A[A-Za-z]([\w\-]*\w)?\z/,
		:message=>'must begin with a letter and only consist of letters, numbers and/or dashes (a-z, 0-9, -)'
	validates_format_of :url, :allow_blank=>true,
		:with=>/\Ahttps?:\/\/[^ \t\r\n]+\z/,
		:message=>'must be a valid URL (starting with ‘http://’)'
	
	validates_exclusion_of :subpath, :in=>WAYGROUND['RESERVED_SUBPATHS'],
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
	has_many :active_memberships, :class_name=>'Membership',
		:conditions=>['(memberships.blocked_at IS NULL OR memberships.blocked_at > NOW() OR memberships.block_expires_at <= NOW()) AND (memberships.expires_at IS NULL OR memberships.expires_at > NOW()) AND memberships.invited_at IS NULL'],
		:order=>'memberships.position', :dependent=>:destroy
	has_many :active_members, :through=>:active_memberships, :source=>:user
	
	has_many :email_messages, :as=>:item, :dependent=>:nullify
	has_many :weblinks, :as=>:item, :dependent=>:destroy
	
	
	# CLASS METHODS
	
	# standard Wayground class methods for displayable items
	def self.default_include
		nil
	end
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'groups.updated_at DESC, ') + 'groups.name'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :only_visible restricts to groups that are visible
	# - :u is the current_user to use to determine access to private items.
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		if p[:only_visible] or p[:u].nil?
			# only public or no user
			strs << '(groups.is_visible = 1)'
		end
		unless p[:key].blank?
			strs << "(groups.name LIKE ? OR groups.subpath LIKE ? OR groups.description LIKE ?)"
			vals += ["%#{p[:key]}%"] * 3
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
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
	
	# Expects a string “email@address” or “<email@address>” or “Name <email@address>”.
	# Returns an array [email, name] or nil if not an email line.
	# (used by bulk Membership processing for Groups)
	def self.line_to_email(line)
		match = line.match(/^ *((.*) +)?<?([A-Za-z0-9]+([A-Za-z0-9_\+=.\-]*[A-Za-z0-9])?@[A-Za-z0-9]+[A-Za-z0-9.\-]*\.[A-Za-z0-9]+)>?,?[ \r]*$/)
		if match
			[match[3], match[2]]
		else
			nil
		end
	end
	
	
	# INSTANCE METHODS
	
	# use the group’s subpath instead of the id
	def to_param
		subpath
	end
	
	# Return the membership for the user, if there is one
	def user_membership(u)
		memberships.find_by_user_id(u.id) rescue nil
	end
	def user_can_access?(u)
		if is_public
			return true
		else
			m = user_membership(u)
			return (m and m.active?)
		end
	end
	def user_can_admin?(u)
		if u.nil?
			return false
		elsif u.admin? or (u == self.owner)
			return true
		else
			m = user_membership(u)
			return (m and m.is_admin and m.active?)
		end
	end
	def user_can_join?(u=nil)
		m = user_membership(u)
		if m.nil?
			# users cannot self-subscribe to invite only groups
			!(is_invite_only)
		else
			# user already has a membership
			false
		end
	end
	
	# s - a symbol or an array of symbols (which any of which matching will return true)
	# u - the user to check access for
	def has_access_to?(s, u)
		if self.owner == u or (u and (u.admin? or u.staff?))
			true
		else
			has_access = false
			m = user_membership(u)
			if s.is_a? Symbol
				s = [s]
			end
			s.each do |sym|
				case sym
				when :self_join
					if m and (m.active? or m.blocked?)
						# already member, or blocked, so can’t join
					elsif is_invite_only
						has_access ||= (m and m.has_access_to?([sym]))
					elsif m.nil?
						has_access = true
					end
				when :member_list
					if is_members_visible
						has_access = true
					elsif m
						has_access ||= (m and m.has_access_to?([sym]))
					end
				#when :manage_members
				#when :inviting
				else
						has_access ||= (m and m.has_access_to?([sym]))
				end
			end
			has_access
		end
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
	
	# Takes a string of email addresses (with optional names)
	# and adds them as Group members.
	# Creates new contacts where none match supplied addresses.
	# Returns a hash:
	# :memberships - list of 
	def bulk_add(bulk, admin_user=nil)
		memberships = []
		added = 0
		blanks = 0
		bad_lines = []
		lines = bulk.scan(/^.*$/)
		line_count = 0
		lines.each do |line|
			line_count += 1
			if line.blank?
				blanks += 1
			else
				email, name = Group.line_to_email(line)
				if email.blank?
					bad_lines << [line_count, line]
				else
					user = User.find_matching_email({:email=>email, :name=>name})
					if user.nil?
						# no user matched, so create new one
						if name.blank?
							# use the first part of the email address as the user name
							# (User model requires fullname to be set)
							fullname = email.sub(/@.+$/, '').gsub(/[^A-Za-z0-9 \-]/, ' ')
						else
							fullname = name
						end
						user = User.create(:fullname=>fullname, :email=>email)
					else
						# check if there is already a membership for the user
						membership = user_membership(user)
						# if there is, make sure the membership is active
						if membership and !(membership.active?)
							membership.make_active!
							added += 1
						end
					end
					if membership.nil?
						# create a Membership if the user doesn’t have one
						membership = Membership.new()
						membership.group = self
						membership.user = user
						membership.inviter = admin_user
						membership.save!
						added += 1
					end
					memberships << membership
				end
			end
		end
		{:memberships=>memberships, :added=>added, :blanks=>blanks, :bad_lines=>bad_lines}
	end
	
	def bulk_remove(bulk)
		missing = []       # email addresses with no membership
		users_removed = [] # the users who had their memberships removed
		blanks = 0         # number of blank lines in bulk
		bad_lines = []     # number of unparsable lines in bulk
		lines = bulk.scan(/^.*$/)
		line_count = 0
		lines.each do |line|
			line_count += 1
			if line.blank?
				blanks += 1
			else
				email, name = Group.line_to_email(line)
				if email.blank?
					bad_lines << [line_count, line]
				else
					removed_this_one = false
					users = User.find_all_matching_email(email)
					users.each do |user|
						membership = user_membership(user)
						unless membership.nil? || !(membership.active?)
							membership.destroy
							users_removed << user
							removed_this_one = true
						end
					end
					unless removed_this_one
						missing << line
					end
				end
			end
		end
		{:users_removed=>users_removed, :missing=>missing, :blanks=>blanks,
			:bad_lines=>bad_lines}
	end
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		"#{name_prefix}group"
	end
	def link
		self
	end
	def title
		name
	end
	def title=(t)
		raise Exception.new('should not assign to Group#title. use name instead')
	end
	def title_prefix
		nil
	end
end
