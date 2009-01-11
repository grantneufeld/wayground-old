module Wayground
	# The supplied XML Tag is not of a recognized class.
	class InvalidChunkXMLTag < Exception; end
	# The specified ItemType is not valid.
	class InvalidItemType < Exception; end
	# Using an instance of an abstract class.
	class AbstractClassUsed < Exception; end
end

# Abstract.
class Chunk
	attr_accessor :block, :flavour # :page_id, :position
	
	
	# CLASS METHODS
	
	# Create a Chunk object (actually, one of the subclasses) from an xml tag.
	def self.from_xmltag(xmltag, content=nil)
		chunk = nil
		if xmltag.is_a? String
			# parse the xmltag
			parsed = {}
			xmltag.scan /([a-z_]+)="([^"]+)"/ do |match|
				parsed[match[0]] = match[1]
			end
			chunk = self.create(parsed.merge({'content'=>content}))
			#case parsed['type']
			#when 'raw'
			#	chunk = RawChunk.create()
			#when 'item'
			#	chunk = ItemChunk.create(parsed)
			#when 'list'
			#	chunk = ListChunk.create(parsed)
			#else
			#	# unrecognized type attribute for wg:chunk xml tag
			#	raise Wayground::InvalidChunkXMLTag
			#end
		else
			raise Wayground::InvalidChunkXMLTag
		end
		chunk
	end
	
	# copied from ActiveRecord::Base
	def self.create(attrs = nil, &block)
		if attrs.is_a?(Array)
			attrs.collect { |attr| create(attr, &block) }
		else
			case attrs['type']
			when 'raw'
				object = RawChunk.new(attrs)
			when 'item'
				object = ItemChunk.new(attrs)
			when 'list'
				object = ListChunk.new(attrs)
			when nil
				if self == Chunk
					# no type attribute and not explicitly calling from subclass
					raise Wayground::InvalidChunkXMLTag
				else
					object = new(attrs)
				end
			else
				# type attribute is not recognized
				raise Wayground::InvalidChunkXMLTag
			end
			yield(object) if block_given?
			#object.save
			object
		end
	end
	def update(id, attrs)
		if id.is_a?(Array)
			idx = -1
			id.collect { |one_id| idx += 1; update(one_id, attrs[idx]) }
		else
			object = find(id)
			object.attributes = attrs
			object
		end
	end
	
	def self.accessible_attrs
		['page_id', 'block', 'position', 'flavour']
	end


	# INSTANCE METHODS

	def initialize(attrs = nil)
		self.attributes = attrs
	end
	
	def attr_accessible?(key)
		self.class.accessible_attrs.include? key
	end
	
	def attributes=(a)
		unless a.nil?
			a.each do |k, v|
				send(k + "=", v) if attr_accessible?(k)
			end
		end
	end
	def attributes
		{'page_id'=>page_id, 'block'=>block, 'position'=>position,
			'flavour'=>flavour}
	end
	
	# Required method for subclasses
	def xmltag_type
		raise Wayground::AbstractClassUsed
	end
	def as_xmltag
		attr_strs = []
		attributes.each do |k,v|
			attr_strs << "#{k}=\"#{v}\"" unless v.blank? or k == 'content'
		end
		"<wg:chunk type=\"#{xmltag_type}\"#{attr_strs.nil? ? '' : ' '}#{attr_strs.join(' ')}#{content.nil? ? ' /' : ''}>"
	end
	def content
		nil
	end
	def close_xmltag
		content.nil? ? nil : '</wg:chunk>'
	end
	def as_xmltag_block
		"#{as_xmltag}#{content}#{close_xmltag}"
	end
	
	def page_id
		@page_id || nil
	end
	def page_id=(p)
		@page = nil # reset page
		@page_id = p.to_i
	end
	def page
		@page ||= !(page_id > 0) ? nil : Page.find(page_id)
	rescue ActiveRecord::RecordNotFound
		nil
	end
	def page=(p)
		@page = p
		page_id = @page.nil? ? nil : @page.id
		@page
	end
	
	def position
		@position || nil
	end
	def position=(p)
		@position = p.to_i
	end
	
	# These functions are used by subclasses, except for RawChunk
	
	# whitelist of classes that can be displayed
	def recognized_item_types
		['Document', 'DocFile', 'DocImage', 'DocPrivate', 'Group', 'Page', 'Path', 'Petition', 'Signature', 'User', 'Weblink']
	end
	
	# t must be a class name for a descendent of ActiveRecord::Base
	def item_type
		@item_type || nil
	end
	def item_type=(t)
		raise Wayground::InvalidItemType unless t.match /\A[A-Z][A-Za-z]+\z/
		raise Wayground::InvalidItemType unless recognized_item_types.include?(t)
		@item_type = t
		@item_class = eval(@item_type)
	end
	def item_class
		@item_class ||= eval(item_type)
	end
	
	def template_id
		@template_id || nil
	end
	def template_id=(t)
		@template = nil # reset template
		@template_id = t.to_i
	end
	def template
		@template ||= !(template_id > 0) ? nil : Template.find(template_id)
	rescue ActiveRecord::RecordNotFound
		nil
	end
	def template=(t)
		@template = t
		template_id = @template.nil? ? nil : @template.id
		@template
	end
end


class RawChunk < Chunk
	attr_accessor :content, :content_type
	
	def self.accessible_attrs
		super + ['content', 'content_type']
	end
	
	def initialize(attrs = nil)
		self.attributes = attrs
	end
	#def attributes=(attrs)
	#	super(attrs)
	#end
	
	def attributes
		super.merge({'content'=>content, 'content_type'=>content_type})
	end
	
	def xmltag_type
		"raw"
	end
end    
       
class ItemChunk < Chunk
	# attr_accessor :item_type, :item_id, :template_id
	
	def self.accessible_attrs
		super + ['item_type', 'item_id', 'template_id']
	end
	
	def attributes
		super.merge({'item_type'=>item_type, 'item_id'=>item_id,
			'template_id'=>template_id})
	end
	
	def xmltag_type
		"item"
	end
	
	def item_type=(t)
		@item = nil #reset item
		super
	end
	def item_id
		@item_id || nil
	end
	def item_id=(i)
		@item = nil # reset item
		@item_id = i.to_i
	end
	
	def item
		@item ||= (item_class.nil? || !(item_id.to_i > 0)) ? nil :
			item_class.find(item_id.to_i)
	rescue ActiveRecord::RecordNotFound
		nil
	end
	def item=(i)
		@item = i
		if @item.nil?
			item_type = nil
			item_id = nil
		else
			item_type = @item.class.name
			item_id = @item.id
		end
		@item
	end
	
end

class ListChunk < Chunk
	attr_accessor :before_date, :after_date, :tags, :key
		# :item_type, :parent_id, :user_id, :max, :paginate, :template_id
	
	def self.accessible_attrs
		super + ['item_type', 'parent_id', 'user_id', 'before_date', 'after_date', 'tags', 'key', 'max', 'paginate', 'template_id']
	end
	
	def attributes
		super.merge({'item_type'=>item_type, 'parent_id'=>parent_id,
			'user_id'=>user_id, 'before_date'=>before_date,
			'after_date'=>after_date, 'tags'=>tags, 'key'=>key, 'max'=>max,
			'paginate'=>paginate, 'template_id'=>template_id})
	end
	
	def xmltag_type
		"list"
	end
	
	def parent_id
		@parent_id || nil
	end
	def parent_id=(p)
		@parent = nil # reset parent
		@parent_id = p.to_i
	end
	def parent
		# TODO: implement the parent constraint for list chunks
		nil
	#	@parent ||= !(parent_id > 0) ? nil : Parent.find(parent_id)
	#rescue ActiveRecord::RecordNotFound
	#	nil
	end
	def parent=(p)
		@parent = p
		parent_id = @parent.nil? ? nil : @parent.id
		@parent
	end
	
	def user_id
		@user_id || nil
	end
	def user_id=(u)
		@user = nil # reset user
		@user_id = u.to_i
	end
	def user
		@user ||= !(user_id > 0) ? nil : User.find(user_id)
	rescue ActiveRecord::RecordNotFound
		nil
	end
	def user=(u)
		@user = u
		user_id = @user.nil? ? nil : @user.id
		@user
	end
	
	def max
		@max || nil
	end
	def max=(m)
		@max = m.to_i
	end
	
	def paginate
		@paginate || false
	end
	def paginate=(p)
		if p and !(['', 0, '0', 'false'].include?(p))
			@paginate = true
		else
			@paginate = false
		end
	end
	
	def items(for_user=nil, offset=nil)
		return nil if item_class.nil?
		# ••• restrict by parent, user, before_date, after_date, tags
		if key.blank?
			conditions = nil
		else
			conditions = item_class.search_conditions(false, for_user, key, true)
		end
		item_class.find(:all, :conditions=>conditions,
			:limit=>max, :offset=>offset,
			:order=>item_class.default_order,
			:include=>item_class.default_include)
	end
end
