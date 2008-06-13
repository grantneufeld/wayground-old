# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	# TODO: NO TESTS HAVE BEEN WRITTEN FOR THESE FUNCTIONS!!!
	
	
	# http://railscasts.com/episodes/77
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
	
	# always format before processing
	# if unconfirmed_urls is set, add ' rel="nofollow"' to anchor elements
	def process_and_format(content, content_type='text/plain', unconfirmed_urls=false)
		process_content format_content(content, content_type, unconfirmed_urls)
	end
	
	def format_content(content, content_type, confirmed_urls=true)
		case content_type
		when 'text/html', '', nil :
			confirmed_urls ? content : mark_unconfirmed_urls(content)
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
		content = simple_format(h(content))
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
	
	# convert the anchors in a block of html to use rel="nofollow" (anti-spam)
	def mark_unconfirmed_urls(content)
		# mark all anchors temporarily
		content.gsub! /(<)[ \t\r\n]*a([ \t\r\n]+[^>]*href[^>]*>)/, '\1•\2'
		# remove rel="follow" if present
		content.gsub! /(<•)([^>]*)([ \t\r\n]rel[ \t\r\n]*=)([\"\']?)([^\"\']+[ \t\r\n])?follow([ \t\r\n][^\"\']+)?(\4)/,
			"\1\2\3\4\5\6\7"
		# nothing to do for anchors already rel="nofollow"
		content.gsub! /(<)•([^>]*)([ \t\r\n]rel[ \t\r\n]*=)([\"\']?)([^\"\']+[ \t\r\n])?(nofollow)([ \t\r\n][^\"\']+)?(\4)/,
			"\1a\2\3\4\5\6\7\8"
		# add nofollow to existing rel attributes
		content.gsub! /(<)•([^>]*)([ \t\r\n]rel[ \t\r\n]*=)([\"\']?)([^\"\']*)(\4)/,
			"\1a\2\3\4\5 nofollow\6"
		# add rel="nofollow" to anchors without rel attributes
		content.gsub! /(<)•([^>]*)/, "\1a\2 rel=\"nofollow\""
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
	# (such as pulling out sidebar chunks and rendering item lists).
	def processable_content_types
		["text/html", "text/plain", "text/markdown", "text/bbcode",
			"text/textilize"]
	end
	
	# Format any item lists and pull out any sidebar chunks,
	# if it is a processable content_type.
	def process_content(content, content_type='text/plain')
		if processable_content_types.include? content_type
			# format 
			content = pull_out_sidebars(substitute_form_authenticity_tokens(
				substitute_item_lists(substitute_document_links(content))
				))
			if false
				content = format_content(
					split_columns(
						pull_out_sidebars(
							substitute_form_authenticity_tokens(
								substitute_item_lists(
									substitute_document_links(
										validate_require_tags(content)
									)
								)
							),
							content_type),
						content_type),
					content_type)
			end
		end
		content
	end
	
	# Returns the content with any {{sidebar}} chunks removed.
	# If a block is specified, each sidebar chunk will be passed to it.
	# The chunk, with whatever modifications are made to it by the block,
	# needs to be returned by the block.
	# Otherwise, if a content_type is specified, that will be used to
	# format_content the chunk.
	# Each (modified) sidebar chunk will then be added to the sidebar.
	def pull_out_sidebars(content) #, content_type=nil, &block)
		trimmed_content = ""
		mode = :content
		content.split(/[ \t\r\n]*\{\{\/?sidebar\}\}[ \t\r\n]*/).each do |chunk|
			if mode == :content
				trimmed_content += chunk
				mode = :sidebar
			else
				#if block
				#	chunk = yield chunk
				#elsif content_type
				#	chunk = format_content(chunk, content_type)
				#end
				unless chunk.blank?
					@content_for_sidebar ||= ""
					@content_for_sidebar +=
						sidebar_section_start + chunk + sidebar_section_end
				end
				mode = :content
			end
		end
		
		trimmed_content
	end
	
	def attrs_scan(tag)
		# parse out the attributes in the items element
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
		content.gsub!(/\{\{\/?document ([^\}]+)\}\}/) do |chunk|
			attrs = attrs_scan($1)
			embed = attrs['embed'] == 'embed'
			begin
				document = Document.find_on_filename(:first, attrs['filename'], current_user)
				if embed and document.image?
					# build image tag
					"<img src=\"#{h document.full_filename}\"" +
						" width=\"#{document.width}\"" +
						" height=\"#{document.height}\"" +
						(['left','right'].include?(attrs['align']) ?
							" align=\"#{attrs['align']}\"" : ''
							) +
						(attrs['class'].blank? ? '' :
							" class=\"#{h attrs['class']}\"") +
						" alt=\"#{h(attrs['content'].blank? ? document.filename :
							attrs['content'])}\"" +
						" title=\"#{h(attrs['title'].blank? ? document.filename :
							attrs['title'])}\"" +
						" />"
				elsif embed and document.content_type = 'text/plain'
					process_and_format document.data, 'text/plain'
				else
					# build document link
					"<a href=\"#{h document.full_filename}\"" +
						(attrs['class'].blank? ? '' :
							" class=\"#{h attrs['class']}\"") +
						" title=\"#{h(attrs['title'].blank? ? document.filename :
							attrs['title'])}\">" +
						"#{h(attrs['content'].blank? ? document.filename :
							attrs['content'])}</a>"
				end
			rescue
				# didn't find document - leave empty
				"<!-- missing document #{attrs['filename']} -->"
			end
		end
		content
	end
	
	# Finds all occurrences of the form authenticity tag and replaces with the
	# correct value.
	# Tag Format:
	# {{form_authenticity}}
	def substitute_form_authenticity_tokens(content)
		content.gsub(/\{\{form_authenticity\}\}/) {
			"<input name=\"authenticity_token\" type=\"hidden\" value=\"#{form_authenticity_token()}\" />"
		}
	end
	
	# Finds all occurrence of the items tag in the content,
	# and replaces them with lists of items.
	# Tag Format:
	# {{items parent="item_id" type="Item" category="category_id" range="current|past|all" sort="desc" on="title|new|date|edit" max="0" info="prefix" pagelinks="after" }}
	def substitute_item_lists(content) #, &block)
		# global page and max values for the entire content
		page = params[:page].to_i
		page = 1 if page < 1
		default_max = params[:max].to_i
		default_max = (default_max.nil? or default_max < 1) ? 10 : default_max
		# process the items tags, returning the revised content
		content.gsub(/\{\{items([^\}]*)\/?\}\}/) { |items_tag|
			# parse out the attributes in the items element
			attrs = {}
			items_tag.scan(/[ \t\r\n]+([a-z]+)=\"([^\"]+)\"/) { |attribute|
				attrs[attribute[0]] = attribute[1]
			}
			
			# figure out the conditions
			condition_strs = []
			conditions = ['']
			if attrs['parent'] and attrs['parent'].to_i > 0
				condition_strs << 'items.parent_id = ?'
				conditions << attrs['parent'].to_i
			end
			unless attrs['type'].blank?
				#condition_strs << 'items.type = ?'
				#conditions << attrs['type']
			end
			unless attrs['category'].blank? or attrs['category'].to_i <= 0
				condition_strs << 'items.category_id = ?'
				conditions << attrs['category'].to_i
			end
			if condition_strs.length == 0 and @item and attrs['type'].blank?
				# if no find constraint, default to the current @item as parent
				condition_strs << 'items.parent_id = ?'
				conditions << @item.id
			end
			# range defaults to "current"
			case attrs['range']
			when 'all'
				# No constraints to add.
			when 'past'
				# TODO: constrain to past events in item lists
			#when 'current'
			else
				if false
					# TODO: Constrain to items that haven't ended/expired yet
					condition_strs <<
						'(items.expires_at IS NULL OR items.expires_at >= NOW())' +
						' AND (items.end_on IS NULL' +
							' OR items.end_on >= CURDATE())' +
						' AND (items.type != "Event"' +
							' OR items.start_on >= CURDATE()' +
							' OR items.sent_at >= CURDATE()' +
							' OR (items.end_on IS NOT NULL' +
								' AND items.end_on >= CURDATE()))'
				end
			end
			# format condition str for find
			if condition_strs.length == 0
				conditions = nil
			else
				conditions[0] = condition_strs.join(' AND ')
			end
			# figure out the sort order
			order = nil
			show_date = nil
			unless attrs['on'].blank?
				sort_direction = attrs['sort'] == 'desc' ? ' desc' : ''
				case attrs['on']
				when 'title' :
					order = "items.title#{sort_direction}, items.id'"
				when 'new' :
					order = "items.created_at#{sort_direction}, items.title, items.id"
					show_date = :new
				when 'date' :
					order = 'items.' + Event.next_at_label.to_s +
						sort_direction +
						', items.start_on' + sort_direction +
						', items.title, items.id'
					show_date = :date
				when 'edit' :
					order = "items.updated_at#{sort_direction}, items.title, items.id"
					show_date = :edit
				end
			end
			# figure out the limit and offset to restrict the list to
			max = attrs['max'].blank? ? max = default_max : attrs['max'].to_i
			max = max < 1 ? default_max : max
			offset = (page - 1) * max
			total = Item.count(:conditions=>conditions)
			
			# get the list
			items = Item.find(:all, :conditions=>conditions, :order=>order,
				:limit=>max, :offset=>offset)#, :readonly=>true)
			###raise Exception.new('items count:' + items.size.to_s + "\nconditions:" + conditions.join(', ') + "\norder:" + order.to_s + "\nmax:" + max.to_s + "\noffset:" + offset.to_s + "\npage:" + page.to_s)
			
			# render the item list
			list_text = ''
			if attrs['info'] == 'prefix'
				# render the info prefix
				list_text += "<p class=\"itemscount\">Showing #{offset + 1} " +
					"through #{items.size + offset} out of #{total} in total.</p>"
			end
			@listitem_previous_heading = nil
			items.each do |item|
				#render_to_string :partial=>
					#	item.controller + '/listitem', :locals=>{:item=>item}
				list_text += @controller.get_partial_as_string(
					item.controller + '/listitem',
					{:item=>item, :show_standard_commands=>true,
						:show_date=>show_date})
			end
			if attrs['pagelinks'] == 'after'
				# render the page links
				#list_text += @controller.render_to_string :partial=>
				#	'layouts/page_links', :locals=>{:page=>page,
				#		:last_page=>((total / max) + ((total % max) > 0 ? 1 : 0))}
				list_text += @controller.get_partial_as_string(
					'layouts/page_links',
					{:page=>page,
					:last_page=>((total / max) + ((total % max) > 0 ? 1 : 0))}
					)
			end
			# return the list text
			list_text
		}
	end	
end
