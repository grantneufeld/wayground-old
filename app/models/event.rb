class Event < ActiveRecord::Base
	attr_accessible :subpath, :next_at, :title, :description, :content, :content_type
	
	validates_presence_of :subpath
	validates_format_of :subpath,
		:with=>/\A[\w\-]+(\.[\w\-]+)?\z/,
		:message=>'must be letters, numbers, dashes or underscores, with an optional extension'
	validates_uniqueness_of :subpath
	
	belongs_to :user
	belongs_to :editor
	belongs_to :group
	belongs_to :parent, :class_name=>'Event'
	has_many :children, :class_name=>'Event', :foreign_key=>'parent_id'
	has_many :schedules
	has_many :rsvps, :through=>:schedules
	has_many :locations, :through=>:schedules
	has_many :tags
end
