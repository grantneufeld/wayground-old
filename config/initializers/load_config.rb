# Load custom config file for current environment 
raw_config = File.read("#{RAILS_ROOT}/config/config.yml") 
WAYGROUND = YAML.load(raw_config)[RAILS_ENV]
# might be able to do the same with just one line:
#WAYGROUND = YAML.load("#{RAILS_ROOT}/config/config.yml")[RAILS_ENV]

# TODO: Need a better way to support multiple sites with shared items off the same db
# In the meantime, using bit flags as defined in the Wayground::SITES constant.

#module Wayground
#	unless defined?(SITES)
#		SITES = {1=>'wayground.ca',
#			2=>'activist.ca', 4=>'arusha.org', 8=>'calgarydollars.ca',
#			16=>'films.arusha.org', 32=>'cd.activist.ca', 64=>'housingaction.ca',
#			128=>'georgeread.ca', 256=>'calgarydemocracy.ca',
#			512=>'albertasocialforum.ca'}
#	end
#end
module Wayground
	unless defined?(SITES)
		SITES = {
			4=>{:name=>'Arusha', :abbrev=>'arusha', :url=>'http://arusha.org'},
			8=>{:name=>'Calgary Dollars', :abbrev=>'caldol',
				:url=>'http://calgarydollars.ca'},
			16=>{:name=>'Action Films', :abbrev=>'actionfilms',
				:url=>'http://films.arusha.org'}
			}
	end
end
