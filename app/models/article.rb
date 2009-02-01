class Article < Page
	# standard Wayground class methods for displayable items
	def self.default_order(p={})
		# TODO: refine sorting of Articles
		(p[:recent].blank? ? '' : 'pages.updated_at DESC, ') +
			'pages.created_at DESC, pages.title'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# - :author is a string to search the author field
	# - :issue is a string to search the issue field
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:key].blank?
			strs << '(pages.title like ? OR pages.description like ? OR pages.content like ? OR pages.keywords like ? OR pages.author like ? OR pages.issue like ?)'
			vals += (["%#{p[:key]}%"] * 6)
		end
		unless p[:author].blank?
			strs << 'pages.author like ?'
			vals << "%#{p[:author]}%"
		end
		unless p[:issue].blank?
			strs << 'pages.issue like ?'
			vals << "%#{p[:issue]}%"
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
end