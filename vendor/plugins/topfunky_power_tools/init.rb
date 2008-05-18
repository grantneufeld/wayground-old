
Test::Unit::TestCase.send :include, Topfunky::TestHelper

# Shamelessly looted from http://svn.techno-weenie.net/projects/plugins/gems/init.rb
#
# Adds vendor directories to the load path.
#
# You still need to +require+ the libraries you are using.
standard_dirs = ['rails', 'plugins']
gems          = Dir[File.join(RAILS_ROOT, "vendor/**") ]
if gems.any?
  gems.each do |dir|
    next if standard_dirs.include?(File.basename(dir))
    lib = File.join(dir, 'lib')
    $LOAD_PATH.unshift(lib) if File.directory?(lib)
  end
end
