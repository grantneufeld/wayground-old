class Weblink < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :position, :category, :title, :site, :url, :description
	
	# item models may include pretty much anything, especially Campaign
	# item models must implement the display_name method
	belongs_to :item, :polymorphic=>true
	belongs_to :user # the submitter of the weblink
	
	validates_presence_of :user
	validates_presence_of :url
	validates_format_of :url, :allow_nil=>true,
		:with=>/\Ahttps?:\/\/[^ \t\r\n]+\z/,
		:message=>'must be a valid URL (starting with ‘http://’)'
	validates_uniqueness_of :url, :scope=>[:item_id], :case_sensitive=>false,
		:message=>'is already in the weblinks for the item'
	
	def before_validation
		set_confirmation
		set_title
		set_site
	end
	
	
	# CLASS METHODS
	
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:key].blank?
			strs << '(weblinks.title LIKE ? OR weblinks.url LIKE ?)'
			vals += ["%#{p[:key]}%"] * 2
		end
		[strs.join(' AND ')] + vals
	end
	def self.default_order
		'weblinks.category, weblinks.position, weblinks.title'
	end
	def self.default_include
		nil
	end
	
	
	# INSTANCE METHODS
	
	# weblinks saved by admin users are always confirmed
	def set_confirmation
		unless is_confirmed?
			if user and (user.admin? or user.staff?)
				is_confirmed = true
				write_attribute :is_confirmed, is_confirmed
			end
		end
	end
	
	# if title is blank, set it to the url website
	def set_title
		if title.blank? and not url.blank?
			# TODO: when weblink title blank, try to retrieve title from remote site
			# else:
			grepped = url.match /\Ahttps?:\/\/([^\/]+)(\/(.*))?/
			if grepped
				title = grepped[1] + (grepped[3].blank? ? '' : '…')
				write_attribute :title, title
			end
		end
	end
	
	# set the site based on the url
	def set_site
		if site.blank? and not url.blank?
			grepped = url.match /\Ahttps?:\/\/([^\/]*\.)?([A-Za-z0-9\-]+)\.([A-Za-z0-9]+)(\/([^\/\?]*))?/
			# chunks:
			# 1: extra leading domain name bits (e.g., 'www')
			# 2: core domain name (e.g., 'facebook')
			# 3: domain name tld (e.g., 'com')
			# 5: 1st chunk after slash after domain name (before next '/' or '?')
			if grepped
				site = grepped[2]
				case site
				when 'blogspot'
					site = 'blogger'
				when 'gnolia'
					site = 'magnolia' if grepped[1] == 'ma.'
				when 'icio'
					if grepped[1] == 'del.' && grepped[3] == 'us'
						site = 'delicious'
					end
				end
				write_attribute :site, site
			end
		end
	end
	
	def is_confirmed?
		is_confirmed
	end
end
