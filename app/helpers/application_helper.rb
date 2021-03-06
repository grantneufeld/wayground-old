require 'xml'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	# TODO: NO TESTS HAVE BEEN WRITTEN FOR THESE FUNCTIONS!!!
	
	include Conversions
	
	# {Destroy Without Javascript}[http://railscasts.com/episodes/77]
	# Creates a friendlier destroy link.
	# (<a href="fallback_url" onclick="confirm_destroy(this,'url')">name</a>)
	# fallback_url should point to a page where the user can confirm the destroy request
	def link_to_destroy(name, url, fallback_url=nil, msg='Are you sure?', options={})
		link_to_function name, "confirm_destroy(this, '#{url}', '#{msg}', '#{form_authenticity_token()}')",
			{:href=>(fallback_url || url)}.merge(options)
	end
	
	
	# ########################################################
	# SIDEBAR:
	# To include a sidebar on a page,
	# wrap each section in:
	#   <% render_sidebar do %>
	#   ...your content here...
	#   <% end %>
	
	def sidebar_section_start(block_class=nil)
		'<div class="sidebar-section' + (block_class ? " #{block_class}" : '') + '">'
	end
	def sidebar_section_end
		'</div>'
	end
	# divide sections of a sidebar: <%= sidebar_split %>
	def sidebar_split
		sidebar_section_end + sidebar_section_start
	end
	def render_sidebar(top=false, block_class=nil, &block)
		if top
			@content_for_sidebar = sidebar_section_start(block_class) + "#{capture(&block)}" + sidebar_section_end + @content_for_sidebar.to_s
		else
			@content_for_sidebar = @content_for_sidebar.to_s + sidebar_section_start(block_class) + "#{capture(&block)}" + sidebar_section_end
		end
		#concat(@content_for_sidebar, block.binding)
	end
	
	
	# ########################################################
	# FORMATTING CONTENT
	
	# confirmed_urls: urls in the content are considered to be confirmed
	# (if not confirmed, mark with anti-spam tag)
	def format_content(content, content_type, confirmed_urls=true)
		case content_type
		when 'text/wayground' :
			# pass through. should be run through :partial=>'layouts/wayground_content'
			content
		when 'text/html', '', nil :
			content = strip_priviledged_elements(content)
			content = mark_unconfirmed_urls(content) unless confirmed_urls
			content
		when 'text/plain' :
			format_plain_text content, confirmed_urls
		when 'text/bbcode' :
			auto_link_with_confirmed(
				sanitize(simple_format_respect_html(bbcodeize(h(content)))),
				confirmed_urls)
		when 'text/markdown' :
			(auto_link_with_confirmed(
				sanitize(markdown(content)), confirmed_urls)
				).gsub(
				/(<p>)?(<\/?)x(div|form)( [^>]+)?(>)(<\/p>)?/, '\2\3\4\5')
		when 'text/textilize' :
			content = sanitize(textilize(content))
			content = mark_unconfirmed_urls(content) unless confirmed_urls
			content
		else
			"<pre>" + h(content) + "</pre>"
		end
	end
	
	# Format plain text, adding paragraphs, breaks, and auto-linking urls.
	# if confirmed_urls is false, add ' rel="nofollow"' to anchor elements
	def format_plain_text(content, confirmed_urls=true)
		# format content
		content = text2html(h(content))
		auto_link_with_confirmed(content, confirmed_urls)
	end
	
	# wrapper for auto_link to deal with unconfirmed urls (anti-spam)
	# if confirmed_urls is false, add ' rel="nofollow"' to anchor elements
	def auto_link_with_confirmed(content, confirmed_urls=true)
		if confirmed_urls
			auto_link(content)
		else
			auto_link(content, :all, {:rel=>'nofollow'})
		end
	end
	
	# if user doesn’t have sufficient permission for them,
	# remove elements that are flagged as class="wg-admin", class="wg-staff", class="wg-stafforadmin", class="wg-login"
	def strip_priviledged_elements(content)
		classes_to_strip = ['wg-admin','wg-staff','wg-stafforadmin','wg-login']
		if current_user
			classes_to_strip.delete('wg-login')
		end
		if current_user and current_user.staff
			classes_to_strip.delete('wg-staff')
			classes_to_strip.delete('wg-stafforadmin')
		end
		if current_user and current_user.admin
			classes_to_strip.delete('wg-admin')
			classes_to_strip.delete('wg-stafforadmin')
		end
		if classes_to_strip.length > 0
			XML.indent_tree_output = false
			parser = XML::Parser.new
			# hide any entities or stray ampersands so the parser doesn’t barf
			content.gsub! '&', '&amp;'
			# create a single temporary root node
			parser.string = "<html>#{content}</html>"
			p = parser.parse
			remove_these = xml_node_strip_priviledged(p.child, classes_to_strip)
			until (n = remove_these.pop).nil? do
				n.remove!
			end
			content = p.child.to_s
			# strip temporary root node html tags
			content.gsub! /[\r\n]*<\/?html>[\r\n]*/, ''
			# reset ampersands
			content.gsub! '&amp;', '&'
		end
		content
	end
	# returns an array of nodes that should be removed
	# classes_to_strip is an array of class names
	def xml_node_strip_priviledged(node, classes_to_strip)
		remove_these = []
		if classes_to_strip.include? node['class']
			# delete the node
			remove_these << node #.remove!
		elsif node.children?
			#check the children of this node
			node.each do |n|
				# recursively parse descendents of this node
				remove_these += xml_node_strip_priviledged(n, classes_to_strip)
			end
		end
		remove_these
	end
	
	# convert the anchors in a block of html to use rel="nofollow" (anti-spam)
	def mark_unconfirmed_urls(content)
		# mark all anchors temporarily
		content.gsub! /(<)[ \t\r\n]*a([ \t\r\n]+[^>]*href)/, '\1•\2'
		# remove rel="follow" if present
		content.gsub! /(<•[^>]*[ \t\r\n]rel[ \t\r\n]*=)([\"\']?)([^\"\']+[ \t\r\n])?follow([ \t\r\n][^\"\']+)?(\2)/,
			'\1\2\3\4\2'
		# nothing to do for anchors already rel="nofollow"
		content.gsub! /(<)•([^>]*)([ \t\r\n]rel[ \t\r\n]*=)([\"\']?)([^\"\']+[ \t\r\n])?(nofollow)([ \t\r\n][^\"\']+)?(\4)/,
			'\1a\2\3\4\5\6\7\4'
		# add nofollow to existing rel attributes
		content.gsub! /(<)•([^>]*)([ \t\r\n]rel[ \t\r\n]*=)([\"\']?)([^\"\']*)(\4)/,
			'\1a\2\3\4\5 nofollow\4'
		# add rel="nofollow" to anchors without rel attributes
		content.gsub! /(<)•([^>]*)/, '\1a\2 rel="nofollow"'
		content
	end
	
	# break text into paragraphs and linebreaks,
	# except where existing html formatting blocks are in place
	def simple_format_respect_html(text)
		# make sure there are enough linebreaks after block close tags
		text.gsub!( /\r?\n?(<\/(blockquote|br|cite|div|h[1-6r]|li|ol|p|pre|ul)>)[\r\n]*/,
			"\n{-}\\1\n\n")
		# hide linebreaks in front of blocks
		text = text.gsub(
			/^[\r\n]*(<(?:blockquote|br|cite|div|h[1-6r]|li|ol|p|pre|ul)>)\r?\n?/,
			"\n{br}\\1")
		
		# add linebreak tags
		text.gsub!( /([^\r\n])(\r?\n|\r)([^\r\n{])/, '\1{br}<br />\3' )
		# tag paragraphs
		#text.gsub!( /^([^\r\n{][^\r\n]*)([\r\n]+)/, "<p>\\1</p>\n" )
		## tag last paragraph
		text.gsub!( /^([^\r\n{][^\r\n]*)(\r?\n?)[\r\n]*$/, "<p>\\1</p>\\2" )
		
		# replace hidden linebreaks
		text.gsub!( /\n?\{br\}/, "\n" )
		text.gsub( /\n?\{-\}/, "" )
	end
	
	
	# ########################################################
	# CONTENT PROCESSING
	#
	# TODO: review the content processing code, write tests
	#
	# THE FOLLOWING METHODS ARE A STRAIGHT COPY FROM THE OLD
	# democracy/app/helpers/application_helper.rb
	# NO EDITING HAS BEEN DONE AND THEY MIGHT NOT WORK!
	
	# Return an array of content_type values that can be processed for
	# formatting
	# (such as pulling out sidebar chunks and rendering page lists).
	def processable_content_types
		['text/wayground', "text/html", "text/plain", "text/markdown",
			"text/bbcode", "text/textilize"]
	end
	
	# Format any page lists and pull out any sidebar chunks,
	# if it is a processable content_type.
	def process_content(content, content_type='text/plain')
		if processable_content_types.include? content_type
			# format 
			#pull_out_sidebars(substitute_form_authenticity_tokens(
			#	substitute_page_lists(substitute_document_links(content))
			#	))
			substitute_form_authenticity_tokens(content)
				#substitute_document_links
			
			#if false
			#	content = format_content(
			#		split_columns(
			#			pull_out_sidebars(
			#				substitute_form_authenticity_tokens(
			#					substitute_page_lists(
			#						substitute_document_links(
			#							validate_require_tags(content)
			#						)
			#					)
			#				),
			#				content_type),
			#			content_type),
			#		content_type)
			#end
		else
			content
		end
	end
	
	def attrs_scan(tag)
		# parse out the attributes in the pages element
		attrs = {}
		tag.scan(/[ \t\r\n]*([a-z0-9\-]+)=\"([^\"]+)\"/) { |attribute|
			attrs[attribute[0]] = attribute[1]
		}
		attrs
	end
	
	# Finds all occurrence of the document tag in the content,
	# and replaces them with document links.
	# If embed is set, image documents will generate image elements,
	# and plain text documents will have their text embedded.
	# For links, the content attribute will be the text shown. If absent, the
	# filename will be used instead.
	# For images, the content attribute will define the alt text.
	# Tag Format:
	# {{document embed="embed" filename="x.txt" content="Link text" title="The Title" class="x" align="left|right"}}
	def substitute_document_links(content)
		# TODO: implement substitute_document_links helper
		#content.gsub!(/\{\{\/?document ([^\}]+)\}\}/) do |chunk|
		#	attrs = attrs_scan($1)
		#	embed = attrs['embed'] == 'embed'
		#	begin
		#		document = Document.find_on_filename(:first, attrs['filename'], current_user)
		#		if embed and document.image?
		#			# build image tag
		#			"<img src=\"#{h document.full_filename}\"" +
		#				" width=\"#{document.width}\"" +
		#				" height=\"#{document.height}\"" +
		#				(['left','right'].include?(attrs['align']) ?
		#					" align=\"#{attrs['align']}\"" : ''
		#					) +
		#				(attrs['class'].blank? ? '' :
		#					" class=\"#{h attrs['class']}\"") +
		#				" alt=\"#{h(attrs['content'].blank? ? document.filename :
		#					attrs['content'])}\"" +
		#				" title=\"#{h(attrs['title'].blank? ? document.filename :
		#					attrs['title'])}\"" +
		#				" />"
		#		elsif embed and document.content_type = 'text/plain'
		#			process_and_format document.data, 'text/plain'
		#		else
		#			# build document link
		#			"<a href=\"#{h document.full_filename}\"" +
		#				(attrs['class'].blank? ? '' :
		#					" class=\"#{h attrs['class']}\"") +
		#				" title=\"#{h(attrs['title'].blank? ? document.filename :
		#					attrs['title'])}\">" +
		#				"#{h(attrs['content'].blank? ? document.filename :
		#					attrs['content'])}</a>"
		#		end
		#	rescue
		#		# didn't find document - leave empty
		#		"<!-- missing document #{attrs['filename']} -->"
		#	end
		#end
		content
	end
	
	# Finds all occurrences of the form tag and inserts a hidden authenticity_token field.
	def substitute_form_authenticity_tokens(content)
		content.gsub(/<form[^>]*>/) {
			"#{$&}\n<input name=\"authenticity_token\" type=\"hidden\" value=\"#{form_authenticity_token()}\" />"
		}
	end
	
	# Returns content converted from one type to another
	# (e.g., from text/plain to text/html)
	def convert_content(content, in_type, out_type, confirmed_urls=true)
		# in_type and out_type must both be set and different
		if in_type.blank? or out_type.blank? or in_type == out_type
			return content
		end
		case out_type
		when 'text/html' :
			# to convert to html, just use the formatter helper used by views
			return format_content(content, in_type, confirmed_urls)
		when 'text/plain' :
			case in_type
			when 'text/html' :
				return html2text(content)
			end
			# non-html text encodings just pass-through as for text/plain
		when 'text/bbcode' :
		when 'text/markdown' :
		when 'text/textilize' :
		end
		return content
	end
	
	def link_to_add_to_list(item, content=nil)
		content ||= '<img src="/icon/list_add.png" alt="Add to List" width="16" height="16" class="icon" />'
		link_to(content, new_listitem_path(:item_type=>item.class.name, :item_id=>item.id), {:title=>'Add this item to a list'})
	end
	
end
