require 'tempfile'

module Conversions
	#--
	# TODO: I wish there was a better way to do this.
	# lynx seems to require that it’s input be a file, or accessed over the net.
	# I couldn’t find a way to get it to process html sent via stdin.
	def html2text(content)
		t = Tempfile.new ['html2text','html']
		t.write content
		t.close
		o = Tempfile.new ['html2text-open','txt']
		o.close
		system "lynx -dump -dont_wrap_pre -force_html -nomargins -nonumbers -nopause  -width=10000 #{t.path} > #{o.path}"
		t.close! # delete the tempfile
		text = o.open.read
		o.close!
		text
	end
	
	# based on Rails’ simple_format
	# adds special formatting for bullet lists
	def text2html(text, html_options={})
		start_tag = '<p>' #tag('p', html_options, true)
		text = text.to_s.dup
		text.gsub!(/\r\n?/, "\n")                    # \r\n and \r -> \n
		# convert ‘*’ lines to unordered (bullet) lists
		text.gsub!(/^[ \t]*\* ?(.*)$/, '<li>\1</li>') # lines start with * -> li
		text.gsub!(/([^>]\n)(<li>)/, "\\1<ul>\n\\2") # first li in group -> open ul
		text.gsub!(/\A\n*(<li>)/, "<ul>\n\\1") # text starts with li -> open ul
		text.gsub!(/(<\/li>\n)([^<])/, "\\1</ul>\n\\2") # last li in group -> close ul
		text.gsub!(/(<\/li>)\n?\z/, "\\1\n</ul>") # text ends with li -> close ul
		# make paragraphs and line breaks
		text.gsub!(/\n\n+/, "</p>\n\n#{start_tag}")  # 2+ newline  -> paragraph
		text.gsub!(/([^>\n]\n)(?=[^<\n])/, '\1<br />') # 1 newline   -> br
		text.insert 0, start_tag
		text << "</p>"
		# cleanup
		text.gsub!(/<p[^>]*>\n*(<ul)/, '\1') # strip p from ul
		text.gsub!(/(<\/ul>)\n*<\/p>/, '\1') # strip /p from /ul
		text
	end
end