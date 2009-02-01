# TODO: support lists for non-logged-in users (cookie storage, or browser local db like in Safari)
class Listitem < ActiveRecord::Base
	attr_accessible :item_id, :item_type, :title
	
	validates_presence_of :item
	validates_presence_of :user
	validates_format_of :title, :with=>/\A([A-Za-z0-9]([A-Za-z0-9 \-]*[A-Za-z0-9])?)?\z/, :allow_nil=>true,
		:message=>'can only use letters, numbers, spaces and dashes; and must start and end with letters or numbers'
	# an item cannot be added more than once to a given user’s list
	validates_uniqueness_of :title, :scope=>[:user_id, :item_type, :item_id]
	
	# TODO: validate that the user has access to the item
	
	belongs_to :item, :polymorphic=>true
	belongs_to :user
	
	def self.default_include
		nil # unfortunately, we can’t eager-load :item because it’s polymorphic
	end
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'listitems.updated_at DESC, ') +
			'listitems.created_at'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# - :title is the list title to match
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		# TODO: support keyword searching in a list of items
		unless p[:title].blank?
			strs << 'listitems.title = ?'
			vals << p[:title]
		end
		if p[:u]
			strs << 'listitems.user_id = ?'
			vals << p[:u]
		end
		#unless p[:key].blank?
		#	strs << 'listitems.title LIKE ?'
		#	vals << "%#{p[:key]}%"
		#end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	def self.find_lists_for_user(u)
		lists = find_by_sql("SELECT listitems.title FROM listitems " +
			"WHERE listitems.user_id = #{u.id} " +
			"GROUP BY listitems.title ORDER BY listitems.title")
	end
	
	def self.count_user_list(u, title)
		Listitem.count(:conditions=>
			['listitems.user_id = ? AND listitems.title = ?', u.id, title])
	end
	
end
