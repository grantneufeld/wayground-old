# Load custom config file for current environment 
raw_config = File.read("#{RAILS_ROOT}/config/config.yml") 
WAYGROUND = YAML.load(raw_config)[RAILS_ENV]
# might be able to do the same with just one line:
#WAYGROUND = YAML.load("#{RAILS_ROOT}/config/config.yml")[RAILS_ENV]
