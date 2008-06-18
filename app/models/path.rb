# Paths define arbitrary URL paths that can be used to access
# displayable model objects (items).
# Paths have a polymorphic relation to models that can be displayed
# (such as Pages, Events, etc.).
class Path < ActiveRecord::Base
	belongs_to :item, :polymorphic=>true
	
	validates_presence_of :sitepath
	validates_uniqueness_of :sitepath
	validates_format_of :sitepath, :allow_nil=>true,
		:with=>/\A\/(([\w_\-]+\/?)+(\.[\w_\-]+|\/)?)?\z/,
		:message=>'must begin with a ‘/’ and be letters, numbers, dashes, underscores and/or slashes, with an optional extension'
	validates_presence_of :redirect, :if=>Proc.new {|p|
		(p.item.nil? && p.item_id.nil?)}
	validates_format_of :redirect, :allow_nil=>true,
		:with=>/\A(https?:\/\/.+|\/(([\w_\-]+\/?)+(\.[\w_\-]+|\/)?)?)\z/,
		:message=>'must begin with a valid URL (including ‘http://’) or a valid root-relative sitepath (starts with a slash ‘/’)'
	
	
	# the home page is a special page
	def self.find_home
		@@home_path ||= find(:first, :conditions=>'sitepath = "/"')
	end
	
	# keyword search
	def self.find_by_key(key) #, parent=nil)
		key_arg = "%#{key}%"
		find(:all, :conditions=>['paths.sitepath like ?', key_arg],
			:order=>'paths.sitepath', :include=>:item)
	end
end
