# TODO: support lists for non-logged-in users (cookie storage, or browser local db like in Safari)
class Listitem < ActiveRecord::Base
	attr_accessible :item_id, :item_type, :title
	
	validates_presence_of :list
	validates_presence_of :item
	#validates_presence_of :user
	# an item cannot be added more than once to a given list
	validates_uniqueness_of :item_id, :scope=>[:list_id, :item_type]
	
	# TODO: validate that the user has access to the item
	
	belongs_to :list
	belongs_to :item, :polymorphic=>true
	#belongs_to :user
	
	
	def self.default_include
		nil # unfortunately, we can’t eager-load :item because it’s polymorphic
	end
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'listitems.updated_at DESC, ') +
			'listitems.position'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	## - :key is a search restriction key
	## - :u is the current_user to use to determine access to private items.
	## - :title is the list title to match
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		#if p[:u]
		#	strs << 'listitems.user_id = ?'
		#	vals << p[:u]
		#end
		# TODO: support keyword searching in a list of items
		#unless p[:key].blank?
		#	strs << 'listitems.title LIKE ?'
		#	vals << "%#{p[:key]}%"
		#end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	
	def before_save
		if self.position.nil? or self.position == 0
			autoset_position
		end
	end
	
	def autoset_position
		last_item = list.listitems.find(:last, :order=>'listitems.position')
		self.position = last_item.position + 1
	end
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		self.item.css_class(name_prefix)
	end
end
