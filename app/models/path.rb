# Paths define arbitrary URL paths that can be used to access
# displayable model objects (items).
# Paths have a polymorphic relation to models that can be displayed
# (such as Pages, Events, etc.).
class Path < ActiveRecord::Base
	belongs_to :item, :polymorphic=>true
	
	validates_uniqueness_of :sitepath
	
	# the home page is a special page
	def self.find_home
		find(:first, :conditions=>'sitepath = "/"')
	end
	
	# TODO: Support for redirect paths
	
end
