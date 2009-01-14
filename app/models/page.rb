# Pages for display on the website.
class Page < ActiveRecord::Base
	# restrict which attributes users can set directly
	attr_accessible :subpath, :title, :description, :content, :content_type,
		:keywords,
		:author, :issue, :published_on # fields for Article
	
	validates_presence_of :subpath
	validates_presence_of :title
	validates_presence_of :content_type, :if=>Proc.new {|p| !(p.content.blank?)}
	validates_format_of :subpath,
		:with=>/\A([\w\-](\.?[\w\-]+)*)?\/?\z/,
		:message=>'must be letters, numbers, dashes or underscores, with an optional extension'
	validates_uniqueness_of :subpath, :scope=>[:site_id, :parent_id]
	validates_format_of :content_type, :allow_nil=>true, :with=> /\A(application|audio|image|message|multipart|text|video)\/[\w\-]+\z/,
		:message=>'is not a valid mimetype'
	
	belongs_to :site, :readonly=>true
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
	def self.find_home(site_id = nil)
		@@home_page ||= nil
		if @@home_page.nil?
			home_path = Path.find_home(site_id)
			@@home_page = home_path.item unless home_path.nil?
		end
		@@home_page
	end
	# find all of the site home pages
	def self.find_homes
		homes = []
		Path.find_homes.each do |p|
			homes << p.item
		end
		homes
	end
	
	# keyword search
	def self.find_by_key(key) #, parent=nil)
		find(:all, :conditions=>search_conditions({:key=>key}),
			:order=>default_order)
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :u is the current_user to use to determine access to private items.
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		unless p[:key].blank?
			strs << '(pages.title like ? OR pages.description like ? OR pages.content like ? OR pages.keywords like ?)'
			vals += (["%#{p[:key]}%"] * 4)
		end
		[strs.join(' AND ')] + vals
	end
	def self.default_order
		'pages.title'
	end
	def self.default_include
		nil
	end
	
	
	# ########################################################
	# Instance Methods
	
	def before_validation
		if parent.nil? and subpath != '/'
			home = self.class.find_home
			home.children << self unless home.nil? or self.id == home.id
		end
		self
	end
	def after_validation
		set_sitepath!
		self
	end
	def before_save
		# convert chunks to content, if needed
		unless @chunks.nil?
			chunks_to_content
		end
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
			self.sitepath = ''
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
	
	# Returns true if this Page is the home page (sitepath == "/")
	def is_home?
		sitepath == '/'
	end
	
	def css_class(prefix='')
		"#{prefix}#{subpath == '/' ? 'root' : self.class.name.downcase}"
	end
	
	def chunks
		if @chunks.nil?
			@chunks = Chunk.array_from_text(content)
			if @chunks.size < 1
				# the content had no chunk tags, so make it a raw chunk
				chunk = RawChunk.new
				chunk.page = self
				chunk.part = 'content'
				chunk.position = 1
				chunk.content = self.content
				chunk.content_type = self.content_type
				@chunks << chunk
			elsif @chunks.size > 1
				chunks_sort!
			end
		end
		@chunks
	end
	def chunks=(a)
		content_will_change!
		@chunks = a
	end
	# Ensure the Page’s chunks are sorted by part and position
	def chunks_sort!
		unless @chunks.nil? or @chunks.size <= 1
			@chunks.sort! {|a,b|
				x = a.part <=> b.part
				if x == 0
					a.position <=> b.position
				else
					x
				end
			}
		end
	end
	
	protected
	
	def chunks_to_content
		if @chunks.nil?
			# do nothing to the content
		elsif @chunks.size == 0
			self.content = ''
			self.content_type = 'text/html'
		elsif @chunks.size == 1 and @chunks[0].is_a? RawChunk
			# If there’s just one chunk and it’s raw, just use it for the content
			self.content = @chunks[0].content
			self.content_type = @chunks[0].content_type
		else
			chunks_sort!
			chunk_strs = @chunks.collect {|c| c.to_s }
			self.content = chunk_strs.join("\r")
			self.content_type = 'text/wayground'
		end
	end
end
