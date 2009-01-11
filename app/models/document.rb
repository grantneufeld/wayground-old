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
	# Updating
	
	# TODO: changing the filename
	#def change_filename(n)
	#	@old_filename ||= filename
	#	filename = n
	#	write_attribute(:filename, n)
	#end
	
	# TODO: changing the site
	#def change_site(s)
	#	@old_site ||= site || nil
	#	site = s
	#	write_attribute(:site_id, s.id)
	#end
	
	#def before_update
	#	unless (@old_filename.nil? || @old_filename == filename) && (@old_site.nil? || @old_site == site)
	#		debugger
	#		# the file path has changed, so move the physical file
	#		old_full_filename = full_filename(nil, @old_filename, @old_site)
	#		FileUtils::mv(old_full_filename, full_filename)
	#	end
	#end
	
	
	# ########################################################
	# Class Methods
	
	# create a new Document object using the appropriate subclass
	# params should contain :uploaded_data and an optional :site_id
	def self.new_doc(params, user, is_private=false)
		if is_private
			doc = DocPrivate.new(params)
		elsif params && params['uploaded_data'] && params['uploaded_data'].content_type.match(/\Aimage\//)
			doc = DocImage.new(params)
		else
			doc = DocFile.new(params)
		end
		doc.user = user
		doc
	end
	
	# A wrapper for find that takes a User as the first param.
	# Enforces security restrictions on document access.
	# TODO: • WARNING: Doesn’t handle a hash for condition args:
	#	:conditions=>['string',{args}]
	def self.find_for_user(u=nil, *args)
		condition_strs = []
		condition_args = []
		# don't include thumbnails in regular finds
		condition_strs << '(documents.thumbnail IS NULL OR documents.thumbnail = "")'
		# restrict private docs from being shown unless user has access
		# TODO: future: support privacy restrictions on find
		if u.nil?
			condition_strs << 'documents.type != "DocPrivate"'
		elsif u.admin?
			# no restrictions for admins
		else
			condition_strs << '(documents.type != "DocPrivate" OR documents.user_id = ?)'
			condition_args << u.id
		end
		
		# detach the options to make them easier to work with
		options = args.last.is_a?(Hash) ? args.pop : {}
		
		# insert conditions into options
		if options[:conditions].is_a? Array
			if options[:conditions].size > 1 && options[:conditions][1].is_a?(Hash)
				# unsupported format for :conditions
				raise
			else
				if options[:conditions][0].blank?
					options[:conditions][0] = condition_strs.join(' AND ')
				else
					condition_strs.insert 0, "(#{options[:conditions][0]})"
					options[:conditions][0] = condition_strs.join(' AND ')
				end
				options[:conditions] += condition_args
			end
		elsif options[:conditions].blank?	
			options[:conditions] = [condition_strs.join(' AND ')] + condition_args
		elsif options[:conditions].is_a? String
			condition_strs.insert 0, "(#{options[:conditions]})"
			options[:conditions] = [condition_strs.join(' AND ')] + condition_args
		else
			# unsupported format for :conditions
			raise
		end
		
		# (re)attach the options to the args
		if options and options.size > 0
			args << options
		end
		# pass the call to the usual ActiveRecord find method
		self.find(*args)
	end
	
	# return a conditions string for find.
	# u is the current_user to use to determine access to private documents.
	# key is a search restriction key
	# only_active is ignored (used in some other classes)
	def self.search_conditions(only_public=false, u=nil, key=nil, only_active=false)
		s = ['(documents.thumbnail IS NULL OR documents.thumbnail = "")']
		if only_public or u.nil?
			# only public or no user
			s[0] = 'documents.type != "DocPrivate" AND ' + s[0]
		elsif u.admin?
			# no restrictions
		else
			# document is public, or user owns the document
			# TODO: future: search_conditions support for privacy restrictions
			s[0] = '(documents.type != "DocPrivate" OR documents.user_id = ?) AND ' + s[0]
			s << u.id
		end
		unless key.blank?
			s[0] += " AND documents.filename LIKE ?"
			s << "%#{key}%"
		end
		s
	end
	def self.default_order
		'documents.filename'
	end
	def self.default_include
		nil
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
			f = File.new(full_filename)
			if f
				c = f.read
				f.close
				c.to_s
			else
				''
			end
		end
	end
	
	# return true if the document content can be rendered on an html page
	def renderable?
		false #image? or is_text? or (content_type == 'text/html')
	end
	
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
			if attachment_options && attachment_options[:path_prefix]
				@folder_root = attachment_options[:path_prefix].sub(
					/^(public\/)?/, '/')
				@folder_root += '/' unless @folder_root[-1..-1] == '/'
				
			else
				@folder_root = '/'
			end
		end
		@folder_root #is_image? ? Wayground::IMAGE_ROOT : Wayground::FILE_ROOT
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
			"#{size.quo(1073741824).ceil} GB"
		elsif size > 1048575
			"#{size.quo(1048576).ceil} MB"
		elsif size > 1023
			"#{size.quo(1024).ceil} KB"
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
	
	def uploaded_data=(upload)
		@uploaded_data = upload
	end
	def site_select
		site.nil? ? nil : site.id
	end
	def site_select=(s)
		if s.blank? or s.to_i == 0
			site = nil
		else
			site = Site.find(s.to_i)
			write_attribute(:site_id, site.id)
		end
	end
	
	def css_class(prefix='')
		self.is_image? ? "#{prefix}image" : "#{prefix}document"
	end
end
