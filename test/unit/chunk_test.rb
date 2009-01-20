require 'test_helper'
require 'chunk'

class ChunkTest < ActiveSupport::TestCase
	fixtures :pages, :users, :paths

	def default_params(overrides={})
		{:page_id=>1, :part=>'content', :position=>1, :flavour=>'feature'}.merge(overrides)
	end
	def xmltag_from_params(params, close_it=true)
		param_strs = []
		params.each {|k,v| param_strs << "#{k}=\"#{v}\"" unless v.blank?}
		xmltag = "<wg:chunk #{param_strs.join(' ')}#{close_it ? ' /' : ''}>"
	end
	def xmltags_equal(tag1, tag2)
		return false if tag1.size != tag2.size
		attrs1 = {}
		attrs2 = {}
		tag1.scan(/ ([a-z_]+)="([^"]*)"/) {|match| attrs1[match[0]] = match[1]}
		tag2.scan(/ ([a-z_]+)="([^"]*)"/) {|match| attrs2[match[0]] = match[1]}
		attrs1.each {|k,v| return false if v != attrs2[k]}
		return true
	end

	def test_xmltag_raw
		params = default_params({:type=>'raw', :content_type=>'text/plain'})
		xmltag = xmltag_from_params(params, false)
		content = 'This is content for a raw chunk.'
		chunk = Chunk.from_xmltag xmltag, content
		assert_kind_of RawChunk, chunk
		assert_equal params[:page_id], chunk.page_id
		assert_equal params[:part], chunk.part
		assert_equal params[:position], chunk.position
		assert_equal params[:flavour], chunk.flavour
		assert_equal params[:content_type], chunk.content_type
		assert_equal content, chunk.content

		assert xmltags_equal(xmltag, chunk.as_xmltag)
	end
	def test_xmltag_item
		params = default_params({:type=>'item', :item_type=>'Page', :item_id=>pages(:one).id})
		# TODO: test Template support once Template is implemented
		xmltag = xmltag_from_params(params)
		chunk = Chunk.from_xmltag xmltag
		assert_kind_of ItemChunk, chunk
		assert_equal params[:page_id], chunk.page_id
		assert_equal params[:part], chunk.part
		assert_equal params[:position], chunk.position
		assert_equal params[:flavour], chunk.flavour
		assert_equal pages(:one), chunk.item

		assert xmltags_equal(xmltag, chunk.as_xmltag)
	end
	def test_xmltag_list
		params = default_params({:type=>'list', :item_type=>'Page', :key=>nil,
			:paginate=>false, :max=>5})
		#:parent_id=>pages(:one).id, :user_id=>users(:login).id, :before_date, :after_date, :tags, :template_id})
		# TODO: test parent restriction on lists
		# TODO: test User restriction on lists
		# TODO: test date restriction on lists
		# TODO: test Template support once Template is implemented
		xmltag = xmltag_from_params(params)
		chunk = Chunk.from_xmltag xmltag
		assert_kind_of ListChunk, chunk
		assert_equal params[:page_id], chunk.page_id
		assert_equal params[:part], chunk.part
		assert_equal params[:position], chunk.position
		assert_equal params[:flavour], chunk.flavour
		assert_equal params[:key], chunk.key
		assert_equal 5, chunk.max
		assert !(chunk.paginate)
		assert_kind_of Array, chunk.items
		assert_kind_of Page, chunk.items[0]
		assert_equal 5, chunk.items.size

		assert xmltags_equal(xmltag, chunk.as_xmltag)
	end
	def test_xmltag_invalid_types
		# not a string
		assert_raise Wayground::InvalidChunkXMLTag do
			chunk = Chunk.from_xmltag nil
		end
		# empty string
		assert_raise Wayground::InvalidChunkXMLTag do
			chunk = Chunk.from_xmltag ''
		end
		# missing type attribute
		assert_raise Wayground::InvalidChunkXMLTag do
			chunk = Chunk.from_xmltag '<wg:chunk />'
		end
		# missing type attribute
		assert_raise Wayground::InvalidItemType do
			chunk = Chunk.from_xmltag '<wg:chunk type="item" item_type="Invalid" />'
		end
	end
	
	def test_chunk_sort
		chunks = []
		sorted = [nil] * 6
		chunk = Chunk.create({'type'=>'list', 'part'=>'sidebar', 'position'=>3})
		chunks << chunk
		sorted[5] = chunk
		chunk = Chunk.create({'type'=>'raw', 'part'=>'content', 'position'=>3})
		chunks << chunk
		sorted[2] = chunk
		chunk = Chunk.create({'type'=>'list', 'part'=>'sidebar', 'position'=>2})
		chunks << chunk
		sorted[4] = chunk
		chunk = Chunk.create({'type'=>'list', 'part'=>'content', 'position'=>2})
		chunks << chunk
		sorted[1] = chunk
		chunk = Chunk.create({'type'=>'raw', 'part'=>'sidebar', 'position'=>1})
		chunks << chunk
		sorted[3] = chunk
		chunk = Chunk.create({'type'=>'raw', 'part'=>'content', 'position'=>1})
		chunks << chunk
		sorted[0] = chunk
		
		chunks.sort!
		assert_equal sorted, chunks
	end
end
