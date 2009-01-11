class DocImage < Document
	
	# AttachmentFu:
	has_attachment(
		:content_type=>:image,
		:max_size=>20.megabytes,
		:thumbnails=>{:thumb=>'100x100>'},
		:path_prefix=>'public/pic',
		:storage=>:file_system
		)
	validates_as_attachment
	
	before_thumbnail_saved do |thumbnail|
		record = thumbnail.parent
		thumbnail.user = record.user
		thumbnail.site = record.site
	end
	
	def destroy
		FileUtils.rm full_filename
		super
	end
	
	# return true if the document content can be rendered on an html page
	def renderable?
		['image/jpeg', 'image/gif', 'image/png'].include? content_type
	end
	
	def is_image?
		true
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
	
end
