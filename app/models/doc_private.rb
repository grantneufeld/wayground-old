class DocPrivate < Document
	
	# AttachmentFu:
	has_attachment(
		#:content_type=>:image,
		:max_size=>20.megabytes,
		#:thumbnails=>{:thumb=>[100,100]},
		:path_prefix=>'private',
		:storage=>:db_file
		#:processor=>:CoreImage
		)
	validates_as_attachment
	
	# return true if the document content can be rendered on an html page
	def renderable?
		is_image? or is_text? or (content_type == 'text/html')
	end
	
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
	
	# private documents have a separate folder_path
	# n = filename; sub = subfolder
	def folder_path(thumbnail=nil, n=nil, sub=nil)
		n.nil? ? filename : n
	end
	
	def is_private?
		true
	end
	
	# return true if the user can view this document
	def can_view?(u)
		u.admin? || (u == self.user)
		# TODO: support users having explicit permission to view a document
		# TODO: support users belonging to group that has permission to view a document
	end
	
	# TODO: authorize a specific user to access this document
	def add_user_permission(u)
		
	end
	
	# TODO: authorize the members of a group to access this document
	def add_group_permission(g)
		
	end

end
