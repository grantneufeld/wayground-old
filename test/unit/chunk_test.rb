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
	
	
	# CLASS METHODS
	
	def test_chunk_array_from_text
		text = '<wg:chunk type="raw" part="content" position="1" content_type="text/plain">First Content chunk</wg:chunk>' +
			'<wg:chunk type="list" part="content" position="2" item_type="Article" />'
		chunks = Chunk.array_from_text(text)
		assert_equal 2, chunks.size
		assert_equal [ListChunk, RawChunk], [chunks[0].class, chunks[1].class]
	end
	
	def test_chunk_from_xmltag_raw
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

		assert xmltags_equal(xmltag, chunk.as_xmltag), "“#{xmltag}” !=\n“#{chunk.as_xmltag}”"
	end
	def test_chunk_from_xmltag_item
		params = default_params({:type=>'item', :item_type=>'Page', :item_id=>pages(:one).id})
		# TODO: test Template support once Template is implemented
		xmltag = xmltag_from_params(params)
		chunk = Chunk.from_xmltag xmltag
		assert_kind_of ItemChunk, chunk
		assert_equal params[:page_id], chunk.page_id
		assert_equal params[:part], chunk.part
		assert_equal params[:position], chunk.position
		assert_equal params[:flavour], chunk.flavour
		#debugger
		assert_equal pages(:one), chunk.item

		assert xmltags_equal(xmltag, chunk.as_xmltag), "“#{xmltag}” !=\n“#{chunk.as_xmltag}”"
	end
	def test_chunk_from_xmltag_list
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

		assert xmltags_equal(xmltag, chunk.as_xmltag), "“#{xmltag}” !=\n“#{chunk.as_xmltag}”"
	end
	def test_chunk_from_xmltag_invalid_types
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
	
	def test_chunk_create_from_param_array
		chunks = Chunk.create_from_param_array([{'type'=>'raw', 'part'=>'content',
				'position'=>'1', 'content_type'=>'text/plain',
				'content'=>'Test Chunks Array from param array'},
			{'type'=>'list', 'part'=>'sidebar', 'position'=>'1',
				'item_type'=>'Event', 'max'=>'5'}])
		assert_equal 2, chunks.size
		assert chunks[0].is_a?(RawChunk)
		assert chunks[1].is_a?(ListChunk)
	end
	
	def test_chunk_create_from_param_hash
		chunks = Chunk.create_from_param_hash({
			'1_content_1'=>{'type'=>'raw', 'part'=>'content', 'position'=>'1',
				'content_type'=>'text/plain',
				'content'=>'Test Chunks Array from param array'},
			'1_sidebar_1'=>{'type'=>'list', 'part'=>'sidebar', 'position'=>'1',
				'item_type'=>'Event', 'max'=>'5'}
			})
		assert_equal 2, chunks.size
		chunks.sort!
		assert chunks[0].is_a?(RawChunk)
		assert chunks[1].is_a?(ListChunk)
	end
	
	def test_chunk_create
		chunk = Chunk.create({'type'=>'raw', 'part'=>'content', 'position'=>'1',
			'content_type'=>'text/plain', 'content'=>'Test Chunk.create'})
		assert chunk.is_a?(RawChunk)
		assert_equal 'content', chunk.part
		assert_equal 1, chunk.position
		assert_equal 'text/plain', chunk.content_type
		assert_equal 'Test Chunk.create', chunk.content
	end
	def test_chunk_create_with_array
		chunks = Chunk.create([
			{'type'=>'raw', 'part'=>'content', 'position'=>'1',
				'content_type'=>'text/plain', 'content'=>'Test Chunk.create array'},
			{'type'=>'list', 'part'=>'sidebar', 'position'=>'1',
				'item_type'=>'Event', 'max'=>'5'}
			])
		assert_equal 2, chunks.size
		assert chunks[0].is_a?(RawChunk)
		assert chunks[1].is_a?(ListChunk)
	end
	def test_chunk_create_invalid_type
		assert_raise Wayground::InvalidChunkXMLTag do
			chunk = Chunk.create({'type'=>'invalid', 'part'=>'content', 'position'=>'1',
				'content_type'=>'text/plain', 'content'=>'Test Chunk.create invalid type'})
		end
	end
	def test_chunk_create_no_type
		assert_raise Wayground::InvalidChunkXMLTag do
			chunk = Chunk.create({'part'=>'content', 'position'=>'1',
				'content_type'=>'text/plain', 'content'=>'Test Chunk.create no type'})
		end
	end
	def test_chunk_create_no_type_with_subclass
		chunk = RawChunk.create({'part'=>'content', 'position'=>'1',
			'content_type'=>'text/plain', 'content'=>'Test RawChunk.create'})
		assert_equal 'Test RawChunk.create', chunk.content
	end
	
	def test_chunk_accessible_attrs
		assert_equal ['flavour', 'page_id', 'part', 'position'], Chunk.accessible_attrs.sort
	end
	
	
	# INSTANCE METHODS
	
	def test_chunk_initialize
		
	end
	
	def test_chunk_sort # <=>
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
	
	def test_chunk_update
		
	end
	
	def test_chunk_attr_accessible
		
	end
	
	def test_chunk_attributes
		
	end
	
	def test_chunk_attributes_assignment
		
	end
	
	def test_chunk_chunk_type
		chunk = Chunk.new
		assert_raise Wayground::AbstractClassUsed do
			chunk.chunk_type
		end
	end
	
	def test_chunk_as_xmltag
		
	end
	
	def test_chunk_content
		
	end
	
	def test_chunk_close_xml_tag
		chunk = Chunk.new
		assert_nil chunk.close_xmltag
	end
	def test_chunk_close_xml_tag_with_content
		chunk = RawChunk.create({:content_type=>'text/plain', :content=>'content for close'})
		assert_equal '</wg:chunk>', chunk.close_xmltag
	end
	
	def test_chunk_as_xmltag_with_content
		chunk = RawChunk.create({:content=>'xml with content'})
		assert_equal '<wg:chunk type="raw">xml with content</wg:chunk>',
			chunk.as_xmltag_with_content
	end
	
	def test_chunk_to_s
		chunk = ListChunk.create({})
		assert_equal '<wg:chunk type="list" />', chunk.to_s
	end
	def test_chunk_to_s_with_content
		chunk = RawChunk.create({:content=>'xml with content'})
		assert_equal '<wg:chunk type="raw">xml with content</wg:chunk>', chunk.to_s
	end
	
	def test_chunk_id
		chunk = Chunk.new({:part=>'content', :position=>'1', :type=>'raw'})
		chunk.page = pages(:one)
		assert_equal "#{pages(:one).id}_content_1", chunk.id
	end
	
	def test_chunk_id_assignment
		chunk = Chunk.new
		chunk.id = 'test-id'
		assert_equal 'test-id', chunk.id
	end
	
	def test_chunk_page_id
		
	end
	
	def test_chunk_page_id_assignment
		
	end
	
	def test_chunk_page
		chunk = Chunk.new
		assert_nil chunk.page
	end
	def test_chunk_page_with_page_id_set
		chunk = Chunk.new
		chunk.page_id = pages(:one).id
		assert_equal pages(:one), chunk.page
	end
	def test_chunk_page_with_invalid_page_id
		chunk = Chunk.new
		chunk.page_id = 9999999999999
		assert_nil chunk.page
	end
	
	def test_chunk_page_assignment
		
	end
	
	def test_chunk_position
		
	end
	
	def test_chunk_position_assignment
		
	end
	
	def test_chunk_recognized_item_types
		assert_equal ['Article', 'Document', 'Event', 'Group', 'Page', 'Petition', 'Signature', 'User', 'Weblink'],
			Chunk.new().recognized_item_types.sort
	end
	
	def test_chunk_item_type
		
	end
	
	def test_chunk_item_type_assignment
		
	end
	
	def test_chunk_item_class
		
	end
	
	def test_chunk_item_id
		
	end
	
	def test_chunk_item_id_assignment
		
	end
	
	def test_chunk_item
		
	end
	def test_chunk_item_missing
		chunk = ItemChunk.create({'item_type'=>'Page', 'item_id'=>999999999})
		assert_nil chunk.item
	end
	
	def test_chunk_item_assignment
		chunk = ItemChunk.new
		chunk.item = pages(:one)
		assert_equal 'Page', chunk.item_type
		assert_equal pages(:one).id, chunk.item_id
	end
	def test_chunk_item_assignment_nil
		chunk = ItemChunk.new
		chunk.item = pages(:one)
		chunk.item = nil
		assert_nil chunk.item_type
		assert_nil chunk.item_id
	end
	
	#def test_chunk_template_id
	#	
	#end
	#
	#def test_chunk_template_id_assignment
	#	chunk = Chunk.new
	#	chunk.template_id = '1'
	#	assert_equal 1, chunk.template_id
	#end
	#
	#def test_chunk_template
	#	
	#end
	#
	#def test_chunk_template_assignment
	#	
	#end
	
	
	# RawChunk METHODS
	
	#def test_rawchunk_
	#	
	#end
	
	
	# ItemChunk METHODS
	
	#def test_itemchunk_
	#	
	#end
	
	
	# ListChunk METHODS
	
	def test_listchunk_attributes
		
	end
	
	def test_listchunk_chunk_type
		chunk = ListChunk.new
		assert_equal 'list', chunk.chunk_type
	end
	
	def test_listchunk_user_id
		chunk = ListChunk.create(default_params({:user_id=>users(:login).id.to_s}))
		assert_equal users(:login).id, chunk.user_id
	end
	
	def test_listchunk_user_id_assignment
		chunk = ListChunk.create(default_params({:user_id=>users(:login).id.to_s}))
		chunk.user_id = users(:regular).id
		assert_equal users(:regular), chunk.user
	end
	def test_listchunk_user_id_assignment_nil
		chunk = ListChunk.create(default_params({:user_id=>users(:login).id.to_s}))
		chunk.user_id = nil
		assert_equal nil, chunk.user
	end
	def test_listchunk_user_id_assignment_nonexistent
		chunk = ListChunk.create(default_params({:user_id=>users(:login).id.to_s}))
		chunk.user_id = 9999999999
		assert_equal nil, chunk.user
	end
	
	def test_listchunk_user
		chunk = ListChunk.create(default_params({:user_id=>users(:login).id.to_s}))
		assert_equal users(:login), chunk.user
	end
	
	def test_listchunk_user_assignment
		chunk = ListChunk.create(default_params({:user_id=>users(:login).id.to_s}))
		chunk.user = users(:regular)
		assert_equal users(:regular).id, chunk.user_id
	end
	def test_listchunk_user_assignment_nil
		chunk = ListChunk.create(default_params({:user_id=>users(:login).id.to_s}))
		chunk.user = nil
		assert_equal nil, chunk.user_id
	end
	
	def test_listchunk_max
		
	end
	
	def test_listchunk_max_assignment
		
	end
	
	def test_listchunk_paginate
		
	end
	
	def test_listchunk_paginate_assignment
		chunk = ListChunk.create(default_params({:paginate=>'0'}))
		assert_equal false, chunk.paginate
		chunk.paginate = '1'
		assert_equal true, chunk.paginate
	end
	
	def test_listchunk_items
		
	end
	def test_listchunk_items_no_item_class
		chunk = ListChunk.create(default_params)
		assert_nil chunk.items
	end
	
	def test_listchunk_items_articles
		chunk = ListChunk.create(default_params({:item_type=>'Article', :max=>5}))
		items = chunk.items
		assert items.include?(pages(:article_one))
	end
end
