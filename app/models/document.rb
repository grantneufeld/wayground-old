class Document < ActiveRecord::Base
	attr_accessible :uploaded_data, :filename, :site_select,
		:temp_path, :thumbnail_resize_options, :content_type
		# the previous 3 are needed by attachment_fu
	
	validates_format_of :filename,
		:with=>/[A-Za-z0-9_\=\+][A-Za-z0-9_ \.\=\+\-]*(\.[A-Za-z0-9_\=\+\-]+)?/
	validates_uniqueness_of :filename
	
	belongs_to :user
	belongs_to :site, :readonly=>true
	
	
	# ########################################################
	# Class Methods
	
	# create a new Document object using the appropriate subclass
	# params should contain :uploaded_data and an optional :site_id
	def self.new_doc(params, user, is_private=false)
		if is_private
			doc = DocPrivate.new(params)
		elsif params && params[:uploaded_data] && params[:uploaded_data].content_type.match(/\Aimage\//)
			doc = DocImage.new(params)
		else
			doc = DocFile.new(params)
		end
		doc.user = user
		doc
	end
	
	# standard Wayground class methods for displayable items
	def self.default_include
		nil
	end
	def self.default_order(p={})
		if p[:recent].blank?
			'documents.filename'
		else
			'documents.updated_at DESC, documents.filename'
		end
	end
	# Returns a conditions array for find.
	# p is a hash of parameters:
	# - :key is a search restriction key
	# - :only_public restricts to only public documents
	# - :u is the current_user to use to determine access to private items.
	# strs is a list of condition strings (with ‘?’ for params) to be joined by “AND”
	# vals is a list of condition values to be appended to the result array (matching ‘?’ in the strs)
	def self.search_conditions(p={}, strs=[], vals=[])
		strs << '(documents.thumbnail IS NULL OR documents.thumbnail = "")'
		if p[:only_public] or p[:u].nil?
			# only public or no user
			strs << 'documents.type != "DocPrivate"'
		elsif p[:u].admin? or p[:u].staff?
			# no restrictions
		else
			# document is public, or user owns the document
			# TODO: future: search_conditions support for privacy restrictions
			strs << '(documents.type != "DocPrivate" OR documents.user_id = ?)'
			vals << p[:u].id
		end
		unless p[:key].blank?
			strs << 'documents.filename LIKE ?'
			vals << "%#{p[:key]}%"
		end
		strs.size > 0 ? [strs.join(' AND ')] + vals : nil
	end
	
	
	# ########################################################
	# Instance Methods
	
	def before_validation_on_create
		fix_filename
	end
	
	# limit characters and format of filename
	# allows [A-Za-z0-9_ \.\-]+
	# must start with [A-Za-z0-9]
	def fix_filename(x=nil)
		x ||= filename
		unless x.blank?
			# strip unallowed characters
			x.gsub! /[^A-Za-z0-9_ \.\-]+/, ''
			# strip leading special characters
			x.gsub! /\A[_ \.\-]+/, ''
			filename = x
			write_attribute('filename', filename)
		end
	end
	
	# read the file’s content
	def content
		if db_file_id && db_file_id > 0
			db_file.data
		else
			if File.file?(full_filename) and (f = File.new(full_filename))
				c = f.read
				f.close
				c.to_s
			else
				''
			end
		end
	end
	
	# return true if the document content can be rendered on an html page
	# implemented by subclasses
	#def renderable?
	#	false #image? or is_text? or (content_type == 'text/html')
	#end
	
	def is_image?
		['image/gif', 'image/png', 'image/jpeg'].include? content_type
	end
	
	# renderable plain text formats
	def is_text?
		['text/plain', 'text/bbcode', 'text/markdown', 'text/textilize'].include? content_type
	end
	
	def is_private?
		false
	end
	
	# return true if the user can view this document
	def can_view?(u)
		true
	end
	
	
	# ########################################################
	# AttachmentFu support
	
	# Gets the full path to the filename in this format:
	#
	#   # This assumes a model name like MyModel
	#   # public/#{table_name} is the default filesystem path 
	#   RAILS_ROOT/public/my_models/5/blah.jpg
	#
	# Overwrite this method in your model to customize the filename.
	# The optional thumbnail argument will output the thumbnail's filename.
	def full_filename(thumbnail = nil, n=nil, sub=nil)
		"#{attachment_options[:path_prefix]}/#{folder_path(thumbnail,n,sub)}"
	end
	
	def folder_root
		unless @folder_root
			if attachment_options and attachment_options[:path_prefix]
				@folder_root = attachment_options[:path_prefix].sub(
					/^(public\/)?/, '/')
				@folder_root += '/' unless @folder_root[-1..-1] == '/'
				
			else
				@folder_root = '/'
			end
		end
		@folder_root
	end
	
	# handled by subclasses through attachment_fu
	def attachment_options
		{}
	end
	
	# n = filename; s = site
	def folder_path(thumbnail=nil, n=nil, s=nil)
		n = filename if n.nil?
		s = site if s.nil?
		unless thumbnail.blank?
			f, e = split_filename(n)
			case thumbnail.to_s
			when 'thumb'
				modifier = '_t'
			else
				modifier = "_#{thumbnail.to_s}"
			end
			"#{s.nil? ? '' : s.path + '/'}#{f}#{modifier}.#{e}"
		else
			s.nil? ? n : "#{s.path + '/'}#{n}"
		end
	end
	
	def fileurl(thumbnail = nil, n=nil, s=nil)
		"#{folder_root()}#{folder_path(thumbnail,n,s)}"
	end
	
	def siteroot
		if site.nil?
			''
		else
			site.url
		end
	end
	
	def siteurl(thumbnail = nil, n=nil, s=nil)
		"#{siteroot}#{fileurl(thumbnail,n,s)}"
	end

	# returns an array of two elements,
	# the base filename and the (optional) file extension
	def split_filename(n=nil)
		# split on the last period. If none, return an array with just the filename.
		n = filename if n.nil?
		n.split /\.([^\.]+)\Z/
	end
	
	# return a representation of the file size as a string
	def size_str
		if size > 1073741823
			"~#{size.quo(1073741824).ceil} GB"
		elsif size > 1048575
			"~#{size.quo(1048576).ceil} MB"
		elsif size > 1023
			"~#{size.quo(1024).ceil} KB"
		else
			"#{size} B"
		end
	end

	def scale_to_proportional(max_width, max_height)
		if max_width.to_f < width.to_f and max_height.to_f < height.to_f
			if (max_width.to_f / width.to_f) > (max_height.to_f / height.to_f)
				# use height ratio
				scale = max_height.to_f / height.to_f
			else
				# use width ratio
				scale = max_width.to_f / width.to_f
			end
			w = (width.to_f * scale).round
			h = (height.to_f * scale).round
		elsif max_width.to_f < width.to_f
			w = max_width
			h = ((max_width * height).to_f / width.to_f).round
		elsif max_height.to_f < height.to_f
			h = max_height
			w = ((max_height * width).to_f / height.to_f).round
		else
			w = width
			h = height
		end
		return w.to_i, h.to_i
	end
	
	#def uploaded_data=(upload)
	#	@uploaded_data = upload
	#end
	def site_select
		read_attribute(:site_id)
	end
	def site_select=(s)
		if s.blank? or s.to_i == 0
			site = nil
			write_attribute(:site_id, nil)
		else
			site = Site.find(s.to_i)
			write_attribute(:site_id, site.id)
		end
	end
	
	# standard Wayground instance methods for displayable items
	def css_class(name_prefix='')
		self.is_image? ? "#{name_prefix}image" : "#{name_prefix}document"
	end
	def description
		nil
	end
	def title
		filename
	end
	def link
		self
	end
	def title_prefix
		nil
	end
end
