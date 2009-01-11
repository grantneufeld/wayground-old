# Paths define arbitrary URL paths that can be used to access
# displayable model objects (items).
# Paths have a polymorphic relation to models that can be displayed
# (such as Pages, Events, etc.).
class Path < ActiveRecord::Base
	validates_presence_of :sitepath
	validates_uniqueness_of :sitepath
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
	def self.find_home(site_id = nil)
		if site_id.nil?
			@@home_path ||= find(:first,
				:conditions=>'site_id IS NULL AND sitepath = "/"')
		else
			@@home_path ||= find(:first,
				:conditions=>['site_id = ? AND sitepath = "/"', site_id])
		end
	end
	# find all of the home pages for the various sites
	def self.find_homes
		find(:all, :conditions=>'sitepath = "/"')
	end
	
	# keyword search
	def self.find_by_key(key) #, parent=nil)
		find(:all, :conditions=>search_conditions(false, nil, key),
			:order=>default_order, :include=>default_include)
	end
	# return a conditions string for find.
	# only_public is ignored (used in some other classes)
	# u is ignored (used in some other classes)
	# key is a search restriction key
	# only_active is ignored (used in some other classes)
	def self.search_conditions(only_public=false, u=nil, key=nil, only_active=false)
		s = []
		unless key.blank?
			s << 'paths.sitepath like ?'
			s << "%#{key}%"
		end
		s
	end
	def self.default_order
		'paths.sitepath'
	end
	def self.default_include
		:item
	end
	
	# Certain paths should not be created.
	def self.restricted_path?(subpath, parent_path=nil)
		p = "#{(parent_path.nil? || parent_path.sitepath == '/' ? nil : parent_path.sitepath)}/#{subpath}"
		!(p.match(
/^\/(activate|campaigns|candidates|contacts|crm|documents|elections|events|forums|groups|locations|login|offices|pages|parties|paths|people|petitions|policies|sessions|signup|users|votes)(\/.*)?$/
		).nil?)
	end
end
