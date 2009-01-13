require 'test_helper'

class TagTest < ActiveSupport::TestCase
	fixtures :tags, :pages
	
	def test_associations
		assert check_associations
	end
	
	# INSTANCE METHODS
	
	def test_tag_new
		test_title = 'test1'
		t = Tag.create({:title=>test_title})
		assert_valid(t)
		assert_equal test_title, t.title
		assert_equal test_title, t.tag
	end
	def test_tag_title_transliterate
		test_title = 'tëst3åćęłńóśźż'
		test_tag = 'test3acelnoszz'
		t = Tag.create({:title=>test_title})
		assert_equal test_title, t.title
		assert_equal test_tag, t.tag
		assert_valid(t)
	end
	def test_tag_title_lowercase
		test_title = 'Test2'
		test_tag = 'test2'
		t = Tag.create({:title=>test_title})
		assert_equal test_title, t.title
		assert_equal test_tag, t.tag
		assert_valid(t)
	end
	def test_tag_title_strip_nonalphanumerical
		test_title = "“test-4*\r\n\t+ &_@ ¡¿”"
		test_tag = 'test4'
		t = Tag.create({:title=>test_title})
		assert_equal test_title, t.title
		assert_equal test_tag, t.tag
		assert_valid(t)
	end
	def test_tag_title_full_conversion
		test_title = "“TÉst-5*\r\n\t+ &_@ ¡¿”"
		test_tag = 'test5'
		t = Tag.create({:title=>test_title})
		assert_equal test_title, t.title
		assert_equal test_tag, t.tag
		assert_valid(t)
	end
end
