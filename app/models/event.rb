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
	has_many :children, :class_name=>'Event', :foreign_key=>'parent_id'
	has_many :schedules, :order=>'schedules.start_at'
	has_many :rsvps, :through=>:schedules
	has_many :locations, :through=>:schedules
	has_many :tags, :order=>'tags.created_at'
	
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:key].blank?
			strs << '(events.title LIKE ? OR events.description LIKE ? OR events.content LIKE ?)'
			vals += (["%#{p[:key]}%"] * 3)
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
		next_at ||= created_at || Time.now
	end
	
	def css_class(prefix='')
		"#{prefix}event"
	end
end
