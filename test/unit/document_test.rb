require File.dirname(__FILE__) + '/../test_helper'

# FIXME: because the db_file storage used by attachment_fu isn’t a regular class, fixtures don’t work quite right. So, I’ve made a mock DbFile class in the test file so the fixtures will load. There is probably a better way to do this.
class DbFile < ActiveRecord::Base
end

class DocumentTest < ActiveSupport::TestCase
	fixtures :db_files, :sites, :users, :documents
	
	def test_associations
		assert check_associations
		assert_equal users(:login), documents(:text).user
		assert_equal users(:login), documents(:pic).user
		assert_equal users(:login), documents(:private_text).user
	end
	
	
	# CLASS METHODS
	
	def test_document_new_doc_file
		file_data = fixture_file_upload('/files/text.txt','text/plain')
		params = {:uploaded_data=>file_data, :site_select=>sites(:arusha).id}
		doc = Document.new_doc(params, users(:staff))
		assert doc.is_a?(DocFile)
		assert_equal 'text.txt', doc.filename
		assert_equal users(:staff), doc.user
	end
	def test_document_new_doc_image
		file_data = fixture_file_upload('/files/upload.jpg','image/jpeg')
		params = {:uploaded_data=>file_data, :site_select=>sites(:arusha).id}
		doc = Document.new_doc(params, users(:staff))
		assert doc.is_a?(DocImage)
		assert_equal 'upload.jpg', doc.filename
		assert_equal users(:staff), doc.user
	end
	def test_document_new_doc_private
		file_data = fixture_file_upload('/files/text.txt','text/plain')
		params = {:uploaded_data=>file_data, :site_select=>sites(:arusha).id}
		doc = Document.new_doc(params, users(:staff), true)
		assert doc.is_a?(DocPrivate)
		assert_equal 'text.txt', doc.filename
		assert_equal users(:staff), doc.user
	end
	
	def test_document_default_include
		assert_nil Document.default_include
	end
	
	def test_document_default_order
		assert_equal 'documents.filename', Document.default_order
	end
	def test_document_default_order_recent
		assert_equal 'documents.updated_at DESC, documents.filename',
			Document.default_order({:recent=>true})
	end
	
	def test_document_search_conditions
		assert_equal ['(documents.thumbnail IS NULL OR documents.thumbnail = "")' +
			' AND documents.type != "DocPrivate"'],
			Document.search_conditions
	end
	def test_document_search_conditions_only_public
		assert_equal ['(documents.thumbnail IS NULL OR documents.thumbnail = "")' +
			' AND documents.type != "DocPrivate"'],
			Document.search_conditions({:only_public=>true})
	end
	def test_document_search_conditions_only_public_with_user
		assert_equal ['(documents.thumbnail IS NULL OR documents.thumbnail = "")' +
			' AND documents.type != "DocPrivate"'],
			Document.search_conditions({:only_public=>true, :u=>users(:admin)})
	end
	def test_document_search_conditions_user
		assert_equal ['(documents.thumbnail IS NULL OR documents.thumbnail = "")' +
			' AND (documents.type != "DocPrivate" OR documents.user_id = ?)',
			users(:login).id],
			Document.search_conditions({:u=>users(:login)})
	end
	def test_document_search_conditions_admin
		assert_equal ['(documents.thumbnail IS NULL OR documents.thumbnail = "")'],
			Document.search_conditions({:u=>users(:admin)})
	end
	def test_document_search_conditions_staff
		assert_equal ['(documents.thumbnail IS NULL OR documents.thumbnail = "")'],
			Document.search_conditions({:u=>users(:staff)})
	end
	def test_document_search_conditions_key
		assert_equal ['(documents.thumbnail IS NULL OR documents.thumbnail = "")' +
			' AND documents.type != "DocPrivate" AND documents.filename LIKE ?',
			'%keyword%'],
			Document.search_conditions({:key=>'keyword'})
	end
	def test_document_search_conditions_all
		assert_equal ['(documents.thumbnail IS NULL OR documents.thumbnail = "")' +
			' AND documents.type != "DocPrivate" AND documents.filename LIKE ?',
			'%keyword%'],
			Document.search_conditions(
				{:u=>users(:login), :only_public=>true, :key=>'keyword'})
	end
	
	
	# INSTANCE METHODS
	
	def test_document_fix_filename
		name_with_weird_chars = '• ./-É®å$ë filename.file'
		cleaned_name = 'filename.file'
		doc = Document.new({:filename=>name_with_weird_chars})
		assert doc.filename == name_with_weird_chars, :message=>"filename failed to assign"
		doc.valid?
		assert doc.filename == cleaned_name, :message=>"failed to clean the filename"
	end
	
	def test_document_content
		assert_equal documents(:text).size, documents(:text).content.size
		assert_equal documents(:subtext).size, documents(:subtext).content.size
		assert_equal documents(:pic).size, documents(:pic).content.size
		assert_equal db_files(:private_text).data, documents(:private_text).content
		assert_equal documents(:private_text).size,
			Document.find(documents(:private_text).id).content.size
		assert_equal documents(:private_subtext).size,
			documents(:private_subtext).content.size
		doc = Document.new
		assert_equal '', doc.content
		doc.db_file_id = -1
		assert_equal '', doc.content
	end
	
	def test_document_renderable
		assert documents(:text).renderable?
		assert !(documents(:pdf).renderable?)
		assert documents(:pic).renderable?
		assert !(documents(:tiff).renderable?)
		assert documents(:private_text).renderable?
		assert !(documents(:private_pdf).renderable?)
	end
	
	def test_document_is_image
		assert !(documents(:text).is_image?)
		assert documents(:pic).is_image?
		assert !(documents(:pdf).is_image?)
		assert !(documents(:private_text).is_image?)
		assert !(documents(:private_pdf).is_image?)
	end
	
	def test_document_is_text
		assert documents(:text).is_text?
		assert !(documents(:pic).is_text?)
		assert !(documents(:pdf).is_text?)
		assert documents(:private_text).is_text?
		assert !(documents(:private_pdf).is_text?)
	end
	
	def test_document_is_private
		assert !(documents(:text).is_private?) # DocFile
		assert !(documents(:pic).is_private?) # DocImage
		assert documents(:private_text).is_private? # DocPrivate
	end
	
	def test_document_can_view
		# non-private documents can always be viewed
		assert documents(:text).can_view?(nil)
		assert documents(:pic).can_view?(nil)
		# private documents can’t be viewed without a user
		assert !(documents(:private_text).can_view?(nil))
		# owner-user has access
		assert documents(:private_text).can_view?(users(:login))
		# admin and staff users always have access
		assert documents(:private_text).can_view?(users(:staff))
		assert documents(:private_text).can_view?(users(:admin))
		# other non-admin users don't have access
		assert !(documents(:private_text).can_view?(users(:regular)))
	end
	
	def test_document_full_filename
		assert_equal "public/file/text.txt", documents(:text).full_filename
		assert_equal "public/file/arusha/subtext.txt",
			documents(:subtext).full_filename
		assert_equal "public/pic/pic.gif", documents(:pic).full_filename
		assert_equal "public/pic/pic_t.gif",
			documents(:pic).full_filename(:thumb)
		assert_equal "public/pic/pic_x.gif", documents(:pic).full_filename(:x)
		assert_equal "private/private_text.txt",
			documents(:private_text).full_filename
		assert_equal "private/private_subtext.txt",
			documents(:private_subtext).full_filename
	end
	
	def test_document_folder_root
		assert_equal '/file/', documents(:text).folder_root
		assert_equal '/pic/', documents(:pic).folder_root
		assert_equal '/private/', documents(:private_text).folder_root
		doc = Document.new
		assert_equal Document, doc.class
		assert_equal '/', doc.folder_root
	end
	
	def test_document_fileurl
		assert_equal "/file/text.txt", documents(:text).fileurl
		assert_equal "/file/arusha/subtext.txt", documents(:subtext).fileurl
		assert_equal "/pic/pic.gif", documents(:pic).fileurl
		assert_equal "/pic/pic_t.gif", documents(:pic).fileurl(:thumb)
		assert_equal "/pic/pic_x.gif", documents(:pic).fileurl(:x)
		assert_equal "/private/private_text.txt",
			documents(:private_text).fileurl
		assert_equal "/private/private_subtext.txt",
			documents(:private_subtext).fileurl
	end
	
	def test_document_siteroot
		assert_equal '', documents(:text).siteroot
		assert_equal 'http://arusha.org', documents(:subtext).siteroot
		assert_equal '', documents(:pic).siteroot
		assert_equal '', documents(:private_text).siteroot
		assert_equal 'http://arusha.org', documents(:private_subtext).siteroot
	end
	
	def test_document_siteurl
		assert_equal "/file/text.txt", documents(:text).siteurl
		assert_equal "http://arusha.org/file/arusha/subtext.txt",
			documents(:subtext).siteurl
		assert_equal "/pic/pic.gif", documents(:pic).siteurl
		assert_equal "/pic/pic_t.gif", documents(:pic).siteurl(:thumb)
		assert_equal "/pic/pic_x.gif", documents(:pic).siteurl(:x)
		assert_equal "/private/private_text.txt",
			documents(:private_text).siteurl
		assert_equal "http://arusha.org/private/private_subtext.txt",
			documents(:private_subtext).siteurl
	end
	
	def test_document_split_filename
		f, e = documents(:text).split_filename
		assert_equal 'text', f
		assert_equal 'txt', e
		f, e = documents(:pic).split_filename
		assert_equal 'pic', f
		assert_equal 'gif', e
		f, e = documents(:private_text).split_filename
		assert_equal 'private_text', f
		assert_equal 'txt', e
	end
	
	def test_document_size_str
		doc = documents(:text)
		assert_equal "#{doc.size} B", doc.size_str
		doc.size = 0
		assert_equal "0 B", doc.size_str
		doc.size = 1023
		assert_equal "1023 B", doc.size_str
		doc.size = 1024
		assert_equal "~1 KB", doc.size_str
		doc.size = 1025
		assert_equal "~2 KB", doc.size_str
		doc.size = 1048575
		assert_equal "~1024 KB", doc.size_str
		doc.size = 1048576
		assert_equal "~1 MB", doc.size_str
		doc.size = 1048577
		assert_equal "~2 MB", doc.size_str
		doc.size = 1073741823
		assert_equal "~1024 MB", doc.size_str
		doc.size = 1073741824
		assert_equal "~1 GB", doc.size_str
		doc.size = 1073741825
		assert_equal "~2 GB", doc.size_str
	end
	
	def test_document_scale_to_proportional
		# pic’s width = 256 and height = 128
		# fit within a 500x500 box (bigger than the pic)
		w, h = documents(:pic).scale_to_proportional(500,500)
		assert_equal 256, w
		assert_equal 128, h
		# fit within a 100x100 area (smaller than the pic)
		w, h = documents(:pic).scale_to_proportional(100,100)
		assert_equal 100, w
		assert_equal 50, h
		# fit within a wide area smaller than the pic
		w, h = documents(:pic).scale_to_proportional(200,50)
		assert_equal 100, w
		assert_equal 50, h
		# fit within a thin area smaller than the pic
		w, h = documents(:pic).scale_to_proportional(50,100)
		assert_equal 50, w
		assert_equal 25, h
		# fit within a thin area, thinner, but taller
		w, h = documents(:pic).scale_to_proportional(100,200)
		assert_equal 100, w
		assert_equal 50, h
		# fit with a box wider, but shorter
		w, h = documents(:pic).scale_to_proportional(500,100)
		assert_equal 200, w
		assert_equal 100, h
	end
	
	def test_document_site_select
		assert_nil documents(:text).site_select
		documents(:text).site_select = "#{sites(:one).id}"
		assert_equal sites(:one).id, documents(:text).site_select
		documents(:text).site_select = '0'
		assert_nil documents(:text).site_select
	end
	
	def test_document_css_class
		assert_equal 'document', documents(:text).css_class
		assert_equal 'dir-document', documents(:pdf).css_class('dir-')
		assert_equal 'image', documents(:pic).css_class
		assert_equal 'dir-image', documents(:pic_thumb).css_class('dir-')
	end
	
	def test_document_description
		assert_nil documents(:text).description
	end
	
	def test_document_title
		assert_equal documents(:text).filename, documents(:text).title
	end
	
	def test_document_link
		assert_equal documents(:text), documents(:text).link
	end
	
	def test_document_title_prefix
		assert_nil documents(:text).title_prefix
	end
	
	def test_document_destroy_file
		# test that there isn’t already a file of the test name in the directory
		assert !(File.exist? 'public/file/arusha/upload.txt')
		# ‘upload’ (create) a new document
		file_data = fixture_file_upload('/files/upload.txt','text/plain')
		params = {:uploaded_data=>file_data, :site_select=>sites(:arusha).id}
		doc = Document.new_doc(params, users(:staff))
		doc.save!
		# test that the file was saved to the expected directory
		assert File.exist?('public/file/arusha/upload.txt')
		# ‘delete’ (destroy) the document
		doc.destroy
		# test that the file was removed from the directory
		assert !(File.exist? 'public/file/arusha/upload.txt')
	end
	def test_document_destroy_image
		# test that there isn’t already a file of the test name in the directory
		assert !(File.exist? 'public/pic/arusha/upload.jpg')
		# ‘upload’ (create) a new document
		file_data = fixture_file_upload('/files/upload.jpg','image/jpeg')
		params = {:uploaded_data=>file_data, :site_select=>sites(:arusha).id}
		doc = Document.new_doc(params, users(:staff))
		doc.save!
		# test that the file was saved to the expected directory
		assert File.exist?('public/pic/arusha/upload.jpg')
		assert File.exist?('public/pic/arusha/upload_thumb.jpg')
		# ‘delete’ (destroy) the document
		doc.destroy
		# test that the file was removed from the directory
		assert !(File.exist? 'public/pic/arusha/upload.jpg')
		assert !(File.exist? 'public/pic/arusha/upload_thumb.jpg')
	end
end
