# TODO: use subpath as the id for route path lookups instead of the integer id

class Group < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :is_public, :is_visible, :is_invite_only,
		:is_members_visible, :subpath, :name, :url, :description, :welcome
	
	validates_presence_of :subpath
	validates_presence_of :name
	validates_format_of :subpath,
		:with=>/\A[A-Za-z][\w\-]*\z/,
		:message=>'must begin with a letter and only consist of letters, numbers and/or dashes (a-z, 0-9, -)'
	validates_format_of :url, :allow_nil=>true,
		:with=>/\Ahttps?:\/\/[^ \t\r\n]+\z/,
		:message=>'must be a valid URL (starting with ‘http://’)'
	# subpath is globally unique for groups - even if the group has a parent
	# part of this is that the subpath may be used in future to define an
	# email address for the group (e.g., group-subpath@groups.wayground.ca)
	validates_uniqueness_of :subpath
	validates_uniqueness_of :name
	
	belongs_to :creator, :class_name=>'User'
	belongs_to :owner, :class_name=>'User'
	
	belongs_to :parent, :class_name=>'Group'
	has_many :children, :class_name=>'Group', :foreign_key=>'parent_id',
		:order=>'groups.name'
end
