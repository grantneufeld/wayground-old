# since we’re in Canada, and Rails is annoyingly U.S.-centric in it’s timezone functions:
class ActiveSupport::TimeZone
	def self.ca_zones
		all.find_all { |z| z.name =~ /Canada|Saskatchewan|Newfoundland/ }
	end
end

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
	:time_date=>"%l:%M:%S %p on %A, %B %d, %Y",
	:tight=>"%Y/%b/%d %l:%M%p")

## datetime
#	:default=>"%a, %b %e, %Y, %l:%M %p",
#	:long=>"%A, %B %e, %Y, %l:%M %p",
#	:simple=>"%B %e, %Y, %l:%M %p", # long without weekday
#	:short=>"%Y/%m/%d %H:%M",
#	:tight=>"%Y/%b/%d %l:%M%p",
## date
#	:default=>"%a, %b %e, %Y",
#	:long=>"%A, %B %e, %Y",
#	:simple=>"%B %e, %Y", #long without weekday
#	:short=>"%Y/%m/%d",
#	:tight=>"%Y/%b/%d",
## time
#	:default=>"%l:%M %p",
#	:long=>"%l:%M %p",
#	:short=>"%H:%M",
#	:tight=>"%l:%M%p",
