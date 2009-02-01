# Paths define arbitrary URL paths that can be used to access
# displayable model objects (items).
# Paths have a polymorphic relation to models that can be displayed
# (such as Pages, Events, etc.).
class Path < ActiveRecord::Base
	validates_presence_of :sitepath
	validates_uniqueness_of :sitepath, :scope=>[:site_id]
	validates_format_of :sitepath, :allow_nil=>true,
		:with=>/\A\/(([\w_\-]+\/?)+(\.[\w_\-]+|\/)?)?\z/,
		:message=>'must begin with a ‘/’ and be letters, numbers, dashes, underscores and/or slashes, with an optional extension'
	validates_presence_of :redirect, :if=>Proc.new {|p|
		(p.item.nil? && p.item_id.nil?)}
	validates_format_of :redirect, :allow_nil=>true,
		:with=>/\A(https?:\/\/.+|\/(([\w_\-]+\/?)+(\.[\w_\-]+|\/)?)?)\z/,
		:message=>'must begin with a valid URL (including ‘http://’) or a valid root-relative sitepath (starts with a slash ‘/’)'
	
	belongs_to :site, :readonly=>true
	belongs_to :item, :polymorphic=>true
	
	
	# the home page is a special page
	def self.find_home(site_id=nil)
		@@home_path ||= find(:first,
			:conditions=>search_conditions({:site_id=>site_id},
				['sitepath = "/"']))
	end
	# find all of the home pages for the various sites
	def self.find_homes
		find(:all, :conditions=>search_conditions({:site_id=>false},
			['sitepath = "/"']))
	end
	
	def self.default_include
		:item
	end
	def self.default_order(p={})
		(p[:recent].blank? ? '' : 'paths.updated_at DESC, ') + 'paths.sitepath'
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :only_active restricts to only items that have started and not ended
	# - :site_id restricts to specified site, current site if nil. Special Case: false puts no site restriction.
	# - :u is the current_user to use to determine access to private items.
	# - (ignored: :key, :only_active, :site_id, :u)
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	## only_public=false, u=nil, key=nil, only_active=false, site_id=nil
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:site_id] == false
			p[:site_id] ||= WAYGROUND['SITE_ID'] if WAYGROUND['SITE_ID'] > 0
			if p[:site_id].nil?
				strs << 'paths.site_id IS NULL'
			else
				strs << 'paths.site_id = ?'
				vals << p[:site_id]
			end
		end
		unless p[:key].blank?
			strs << 'paths.sitepath LIKE ?'
			vals << "%#{p[:key]}%"
    	end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
    end
	
	# Certain paths should not be created.
	def self.restricted_path?(subpath, parent_path=nil)
		p = "#{(parent_path.nil? || parent_path.sitepath == '/' ? nil : parent_path.sitepath)}/#{subpath}"
		!(p.match(
/^\/(activate|campaigns|candidates|contacts|crm|documents|elections|events|forums|groups|locations|login|offices|pages|parties|paths|people|petitions|policies|sessions|signup|users|votes)(\/.*)?$/
		).nil?)
	end
end
