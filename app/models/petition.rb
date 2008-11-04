class Petition < ActiveRecord::Base
	attr_accessible :subpath, :start_at, :end_at, :public_signatures,
		:allow_comments, :goal, :title, :description, :custom_field_label,
		:country_restrict, :province_restrict, :city_restrict,
		:restriction_description, :content, :thanks_message
	
	belongs_to :user
	has_many :signatures, :order=>'signatures.id', :dependent=>:delete_all
	
	validates_presence_of :subpath
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
end
