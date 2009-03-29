class List < ActiveRecord::Base
	attr_accessible :item_id, :item_type, :title
	
	validates_presence_of :user
	validates_format_of :title, :with=>/\A([A-Za-z0-9]([A-Za-z0-9 ]*[A-Za-z0-9])?)?\z/, :allow_nil=>true,
		:message=>'can only use letters, numbers and spaces; and must start and end with letters or numbers'
	validates_uniqueness_of :title, :scope=>:user_id
	
	belongs_to :user
	has_many :listitems, :order=>'listitems.position'
	
	
	def self.default_include
		nil
	end
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'lists.updated_at DESC, ') +
			'lists.title'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :u is the current_user to use to determine access to private items.
	# - :key is a search restriction key
	# - :user is a User to find lists for (overrides :u, ignores is_public=false)
	## - :title is the list title to match
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		# TODO: support keyword searching in a list of items
		unless p[:title].blank?
			strs << 'lists.title = ?'
			vals << p[:title]
		end
		if p[:user]
			strs << 'lists.user_id = ?'
			vals << p[:user]
		elsif p[:u]
			strs << '(lists.user_id = ? OR lists.is_public = 1)'
			vals << p[:u]
		else
			strs << 'lists.is_public = 1'
		end
		#unless p[:key].blank?
		#	strs << 'lists.title LIKE ?'
		#	vals << "%#{p[:key]}%"
		#end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	def self.find_list_titles_for_user(u)
		lists = find_by_sql("SELECT lists.title FROM lists " +
			"WHERE lists.user_id = #{u.id} " +
			"GROUP BY lists.title ORDER BY lists.title")
		lists.map {|l| l.title}
	end
	
	# find the default
	def self.find_default_list_for_user(u)
		self.find(:first, :include=>self.default_include, :order=>self.default_order,
			:conditions=>self.search_conditions(:user=>u, :title=>''))
	end
	
	
	def subpath
		title.gsub(' ', '-')
	end
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		"#{name_prefix}list"
	end
end
