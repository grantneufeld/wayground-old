require File.dirname(__FILE__) + '/../test_helper'

class DocumentTest < ActiveSupport::TestCase
	fixtures :documents, :users
	
	def test_associations
		assert check_associations
		assert_equal users(:login), documents(:text).user
		assert_equal users(:login), documents(:pic).user
		assert_equal users(:login), documents(:private_text).user
	end
	
	
	# CLASS METHODS
	
	def test_privacy_search_conditions
		search_condition_tests = [
			[false,nil], # find all with no user
			[true,nil], # find only_public with no user
			[false,:login], # find all with owner user
			[true,:login], # find only_public with owner user
			[false,:staff], # find all with non-owner user
			[true,:staff], # find only_public with non-owner user
			[false,:admin], # find all with admin user
			[true,:admin] # find only_public with admin user
			]
		search_condition_tests.each do |sc|
			only_public = sc[0]
			user = sc[1].nil? ? nil : users(sc[1])
			conditions = Document.search_conditions(only_public, user)
			docs = Document.find(:all, :conditions=>conditions)
			bad_docs = expect_privacy(docs, only_public, user)
			assert bad_docs.size == 0, :message=>"found #{bad_docs.size} private documents that should not have been shown when " +
				(user.nil? ? 'no user set' : "users(:#{sc[1]})") +
				(only_public ? " and only public" : '')
		end
	end
	def expect_privacy(docs, only_public=false, user=nil)
		bad_docs = []
		docs.each do |doc|
			if only_public && doc.is_a?(DocPrivate)
				bad_docs << doc
			else
				unless user && user.admin?
					if doc.is_a?(DocPrivate) && doc.user != user
						bad_docs << doc
					end
				end
			end
		end
		bad_docs
	end
	
	
	# INSTANCE METHODS
	
	def test_get_content
		assert_equal documents(:text).size, documents(:text).content.size
		assert_equal documents(:subtext).size, documents(:subtext).content.size
		assert_equal documents(:pic).size, documents(:pic).content.size
		assert_equal documents(:private_text).size,
			documents(:private_text).content.size
		assert_equal documents(:private_subtext).size,
			documents(:private_subtext).content.size
	end
	
	def test_filename_cleanup
		name_with_weird_chars = '• ./-É®å$ë filename.file'
		cleaned_name = 'filename.file'
		[Document, DocFile, DocImage, DocPrivate].each do |doc_class|
			doc = doc_class.new({:filename=>name_with_weird_chars})
			assert doc.filename == name_with_weird_chars,
				:message=>"#{doc_class} filename failed to assign"
			#assert doc.valid?,
			#	:message=>"#{doc_class} failed to validate"
			doc.valid?
			assert doc.filename == cleaned_name,
				:message=>"#{doc_class} failed to clean the filename"
		end
	end
	
	def test_renderable
		assert documents(:text).renderable?
		assert !(documents(:pdf).renderable?)
		assert documents(:pic).renderable?
		assert !(documents(:tiff).renderable?)
		assert documents(:private_text).renderable?
		assert !(documents(:private_pdf).renderable?)
	end
	
	def test_is_text
		assert documents(:text).is_text?
		assert !(documents(:pic).is_text?)
		assert documents(:private_text).is_text?
		assert !(documents(:private_pdf).is_text?)
	end
	
	def test_full_filename
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
	
	def test_folder_root
		assert_equal '/file/', documents(:text).folder_root
		assert_equal '/pic/', documents(:pic).folder_root
		assert_equal '/private/', documents(:private_text).folder_root
	end
	
	def test_fileurl
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
	
	def test_siteroot
		assert_equal '', documents(:text).siteroot
		assert_equal 'http://arusha.org', documents(:subtext).siteroot
		assert_equal '', documents(:pic).siteroot
		assert_equal '', documents(:private_text).siteroot
		assert_equal 'http://arusha.org', documents(:private_subtext).siteroot
	end
	
	def test_siteurl
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
	
	def test_split_filename
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
	
	def test_scale_to_proportional
		# pic’s width = 256 and height = 128
		w, h = documents(:pic).scale_to_proportional(100,100)
		assert_equal 100, w
		assert_equal 50, h
		w, h = documents(:pic).scale_to_proportional(200,100)
		assert_equal 200, w
		assert_equal 100, h
		w, h = documents(:pic).scale_to_proportional(500,500)
		assert_equal 256, w
		assert_equal 128, h
		w, h = documents(:pic).scale_to_proportional(500,100)
		assert_equal 200, w
		assert_equal 100, h
	end
	
	def test_can_view
		# non-private documents can always be viewed
		assert documents(:text).can_view?(users(:activate_this))
		# owner-user has access
		assert documents(:private_text).can_view?(users(:login))
		# admin users always have access
		assert documents(:private_text).can_view?(users(:admin))
		# other non-admin users don't have access
		assert !(documents(:private_text).can_view?(users(:staff)))
	end
	
	def test_new_and_delete_document
		# test that there isn’t already a file of the test name in the directory
		assert !(File.exist? 'public/file/arusha/upload.jpg')
		# ‘upload’ (create) a new document
		file_data = fixture_file_upload('/files/upload.jpg','image/jpeg')
		params = {:uploaded_data=>file_data, :subfolder=>'arusha'}
		doc = Document.new_doc(params, users(:login))
		doc.save!
		# test that the file was saved to the expected directory
		assert File.exist?('public/file/arusha/upload.jpg')
		# ‘delete’ (destroy) the document
		doc.destroy
		# test that the file was removed from the directory
		assert !(File.exist? 'public/file/arusha/upload.jpg')
	end
	
	def test_document_css_class
		assert_equal 'document', documents(:text).css_class
		assert_equal 'dir-document', documents(:pdf).css_class('dir-')
		assert_equal 'image', documents(:pic).css_class
		assert_equal 'dir-image', documents(:pic_thumb).css_class('dir-')
	end
end
