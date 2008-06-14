# Paths define arbitrary URL paths that can be used to access
# displayable (showable) model objects.
# Paths have a polymorphic relation to models that can be displayed
# (such as Items, Events, etc.).
class Path < ActiveRecord::Base
	belongs_to :show, :polymorphic=>true
	
	validates_uniqueness_of :sitepath
	
	# the home page is a special item
	def self.find_home
		find(:first, :conditions=>'sitepath = "/"')
	end
	
	# TODO: Support for redirect paths
	
end
