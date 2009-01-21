class Event < ActiveRecord::Base
	attr_accessible :subpath, :next_at, :title, :description, :content, :content_type
	
	validates_presence_of :subpath
	validates_format_of :subpath,
		:with=>/\A[\w\-]+(\.[\w\-]+)*\z/,
		:message=>'must be letters, numbers, dashes or underscores, with an optional extension'
	validates_uniqueness_of :subpath
	validates_presence_of :title
	validates_presence_of :content_type, :unless=>Proc.new {|p| p.content.blank?}
	validates_inclusion_of :content_type, :allow_nil=>true,
		:in=>%w(text/plain text/html text/wayground),
		:message=>'is not a valid mimetype'
	validates_presence_of :user
	
	belongs_to :user
	belongs_to :editor
	belongs_to :group
	belongs_to :parent, :class_name=>'Event'
	has_many :children, :class_name=>'Event', :foreign_key=>'parent_id',
		:dependent=>:destroy
	has_many :schedules, :order=>'schedules.start_at', :dependent=>:destroy
	has_many :rsvps, :through=>:schedules
	has_many :locations, :through=>:schedules
	has_many :tags, :order=>'tags.created_at'
	
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
				# no conditions set, so set to our conditions
				options ||= {}
				options[:conditions] =
					["(events.subpath = :subpath)",
					{:subpath=>id}]
			elsif options[:conditions].is_a? String
				# conditions are just a raw SQL sub-string, so add our conditions
				options[:conditions] = ["(#{options[:conditions]}) AND (events.subpath = :subpath)",
					{:subpath=>id}]
			elsif options[:conditions].is_a? Array	
				# conditions are an array so mix-in our conditions
				if options[:conditions][1].class == Hash
					# the conditions array is using a parameter hash,
					# so mix-in our conditions as hash values
					options[:conditions][0] = "(#{options[:conditions][0]}) AND (events.subpath = :subpath)"
					options[:conditions][1].merge!({:subpath=>id})
				else
					# conditions array is using '?' parameters,
					# so append our conditions
					options[:conditions][0] =
						"(#{options[:conditions][0]}) AND (events.subpath = ?)"
					options[:conditions] << id
				end
			else
				raise Exception.new("class of supplied conditions is not recognized")
			end
			args << options
			event = super(*args)
			raise ActiveRecord::RecordNotFound if event.nil?
			event
		end
	end
	
	def self.update_next_at_for_all_events(include_null_next=false)
		conds = []
		if include_null_next
			conds << 'events.next_at IS NULL'
		end
		conds << 'events.next_at < NOW()'
		to_update = find(:all, :conditions=>conds.join(' OR '))
		to_update.each do |event|
			event.next_at = event.calculate_next_at
			event.save
		end
	end
	
	# standard Wayground class methods for displayable items
	def self.default_include
		nil
	end
	def self.default_order
		# TODO: should NULL next_at sort after non-NULL?
		'events.next_at, events.start_at'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# - :restrict is :past, :upcoming or nil (for no restrict)
	# TODO: add param(s) to restrict to upcoming or past Events
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:key].blank?
			strs << '(events.title LIKE ? OR events.description LIKE ? OR events.content LIKE ?)'
			vals += (["%#{p[:key]}%"] * 3)
		end
		if p[:restrict] == :upcoming
			strs << '(events.next_at IS NOT NULL)'
		elsif p[:restrict] == :past
			strs << '(events.next_at IS NULL)'
		end
		[strs.join(' AND ')] + vals
	end
	
	def before_validation
		if !(content.blank?) and content_type.blank?
			content_type = 'text/plain'
			write_attribute('content_type', content_type)
		end
	end
	def before_save
		# TODO: Event: calculate next_at and over_at based on schedules
		#debugger
		next_at = calculate_next_at
		write_attribute('next_at', next_at)
	end
	
	# use the event’s subpath instead of the id
	def to_param
		subpath
	end
	
	
	def calculate_next_at(relative_to=Time.now)
		n = nil
		schedules.each do |schedule|
			sn = schedule.next_at(relative_to)
			n = sn if sn and (n.nil? or sn < n)
		end
		n
	end
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		"#{name_prefix}event"
	end
	def link
		self
	end
	def title_prefix
		(next_at.nil? ? start_at : next_at).to_s(:event_date)
	end
end
