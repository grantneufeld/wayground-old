require File.dirname(__FILE__) + '/../test_helper'

class DocImageTest < ActiveSupport::TestCase
	# The full set of tests for the DocImage class are handled in DocumentTest
	
	def test_associations
		assert check_associations(DocImage)
	end
	
	
	# Special cases for images (not handled by regular documents)
	
	def test_thumbnail_creation
		doc = nil
		assert_difference(Document, :count, 2) do
			file_data = fixture_file_upload('/files/upload.jpg','image/jpeg')
			doc = DocImage.new({:uploaded_data=>file_data, :site_select=>sites(:arusha).id})
			doc.user = users(:login)
			assert doc.save
		end
		# check that pic was stored as expected
		pic = Document.find_by_filename('upload.jpg')
		assert_equal doc, pic
		assert pic.is_a?(DocImage)
		assert_equal 448, pic.width
		assert_equal 604, pic.height
		assert_equal 128303, pic.size
		assert_equal users(:login), pic.user
		# check that thumbnail was generated as expected
		thumb = pic.thumbnails.find_by_thumbnail('thumb')
		assert thumb.is_a?(DocImage)
		assert_equal 74, thumb.width
		assert_equal 100, thumb.height
		#assert_equal 'upload_t.jpg', thumb.filename
		assert_equal sites(:arusha), thumb.site
		assert_equal users(:login), thumb.user
		assert(thumb.size > 0)
		assert(thumb.content.size > 0)
		# remove the document and it's thumb
		assert_difference(Document, :count, -2) do
			assert pic.destroy.frozen?
		end
		
		# test with image smaller than scaling
		doc = nil
		assert_difference(Document, :count, 2) do
			file_data = fixture_file_upload('/files/upload64.jpg','image/jpeg')
			doc = DocImage.new({:uploaded_data=>file_data, :site_select=>sites(:arusha).id})
			doc.user = users(:login)
			assert doc.save
		end
		# check that pic was stored as expected
		pic = Document.find_by_filename('upload64.jpg')
		assert_equal doc, pic
		assert pic.is_a?(DocImage)
		assert_equal 64, pic.width
		assert_equal 64, pic.height
		assert_equal 7261, pic.size
		assert_equal users(:login), pic.user
		# check that thumbnail was generated as expected
		thumb = pic.thumbnails.find_by_thumbnail('thumb')
		assert thumb.is_a?(DocImage)
		assert_equal 64, thumb.width
		assert_equal 64, thumb.height
		#assert_equal 'upload64_t.jpg', thumb.filename
		assert_equal sites(:arusha), thumb.site
		assert_equal users(:login), thumb.user
		assert(thumb.size > 0)
		assert(thumb.content.size > 0)
		# remove the document and it's thumb
		assert_difference(Document, :count, -2) do
			assert pic.destroy.frozen?
		end
	end
end
