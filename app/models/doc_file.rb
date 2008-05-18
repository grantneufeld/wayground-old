class DocFile < Document
	
	# AttachmentFu:
	has_attachment(
		:max_size=>20.megabytes,
		:path_prefix=>'public/file',
		:storage=>:file_system
		)
	validates_as_attachment
	
	# return true if the document content can be rendered on an html page
	def renderable?
		is_text? or (content_type == 'text/html')
	end
	
	def is_image?
		false
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
	
	def destroy
		FileUtils.rm full_filename
		super
	end
	
end
