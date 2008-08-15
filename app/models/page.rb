# Pages for display on the website.
class Page < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :subpath, :title, :description, :content, :content_type,
		:keywords
	
	validates_presence_of :subpath
	validates_presence_of :title
	validates_presence_of :content_type, :if=>Proc.new {|p| !(p.content.blank?)}
	validates_format_of :subpath,
		:with=>/\A([\w\-](\.?[\w\-]+)*)?\/?\z/,
		:message=>'must be letters, numbers, dashes or underscores, with an optional extension'
	validates_uniqueness_of :subpath, :scope=>[:parent_id]
	validates_format_of :content_type, :allow_nil=>true, :with=> /\A(application|audio|image|message|multipart|text|video)\/[\w\-]+\z/,
		:message=>'is not a valid mimetype'
	
	belongs_to :user
	belongs_to :editor, :class_name=>"User", :foreign_key=>"editor_id"
	
	# TODO: make page containment polymorphic so pages can be contained by pages groups or maybe even users. This is a significant change that will affect Path objects, too.
	# page containment hierarchy
	belongs_to :parent, :class_name=>"Page", :foreign_key=>"parent_id"
	has_many :children, :class_name=>"Page", :foreign_key=>"parent_id",
		:order=>'title', :dependent=>:nullify
	
	has_one :path, :as=>:item, :dependent=>:destroy
	
	
	# ########################################################
	# Class Methods
	
	# the home page is a special page
	def self.find_home
		@@home_page ||= Path.find_home.item
	end
	
	# keyword search
	def self.find_by_key(key) #, parent=nil)
		key_arg = "%#{key}%"
		find(:all, :conditions=>[
			'pages.title like ? OR pages.description like ? OR pages.content like ? OR pages.keywords like ?',
			key_arg, key_arg, key_arg, key_arg], :order=>'pages.title')
	end
	
	
	# ########################################################
	# Instance Methods
	
	def before_validation
		if parent.nil?
			self.class.find_home.children << self
		end
		self
	end
	def after_validation
		set_sitepath!
		self
	end
	
	def validate
		if Path.restricted_path?(subpath, (parent.nil? ? nil : parent.path))
			errors.add(:subpath,
				"you cannot use the subpath “#{subpath}” — it is reserved")
		end
	end
	
	# access the path.sitepath as if it were an attribute on page
	def sitepath
		unless path
			set_sitepath!
		end
		path.sitepath
	end
	def	sitepath=(p)
		if path
			path.sitepath = p
		else
			self.path = Path.new(:sitepath=>p)
			self.path.item = self
			self.path.valid?
		end
		p
	end
	
	# the path.sitepath is set based on the page’s subpath,
	# and the sitepath of its parent page (if any).
	def set_sitepath!
		old_subpath = self.subpath || self.read_attribute('subpath') || ''
		workpath = old_subpath
		if workpath.blank?
			# TODO? deal with blank subpath when setting sitepath?
		elsif workpath == '/'
			self.sitepath = '/'
		else
			if workpath[0].chr == '/'
				# strip leading / from subpath
				workpath = workpath[1..-1]
			end
			if self.parent
				# make sure the parent's sitepath is set properly
				if self.parent.sitepath.blank?
					self.parent.set_sitepath!
				end
				# get the parent’s sitepath, ensuring there’s a trailing slash
				if self.parent.sitepath[-1].chr == '/'
					parent_path = self.parent.sitepath
				else
					parent_path = self.parent.sitepath + '/'
				end
			else
				# page has no parent
				parent_path = '/'
			end
			self.sitepath = parent_path + workpath.to_s
		end	
		if workpath != old_subpath
			subpath = workpath
			write_attribute("subpath", workpath)
		end
		self
	end
	
	# return an array of the parents of this page, starting with the topmost,
	# and ending with the direct parent of this page
	def parent_chain
		parent.nil? ? [] : parent.parent_chain << parent
	end
	
	def css_class(prefix='')
		"#{prefix}#{subpath == '/' ? 'root' : self.class.name.downcase}"
	end
end
