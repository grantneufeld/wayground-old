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
end