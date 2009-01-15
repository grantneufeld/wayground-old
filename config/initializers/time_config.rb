# since we’re in Canada, and Rails is annoyingly U.S.-centric in it’s timezone functions:
class ActiveSupport::TimeZone
	def self.ca_zones
		all.find_all { |z| z.name =~ /Canada|Saskatchewan|Newfoundland/ }
	end
end

# determine the hours and minutes of the current timezone offset
tzoff_secs = Time.now.gmt_offset
if tzoff_secs < 0
	tzoff_negative = true
	tzoff_secs *= -1
else
	tzoff_negative = false
end
tzoff_minutes = tzoff_secs / 60
tzoff_hours = tzoff_minutes / 60
tzoff_minutes = tzoff_minutes % 60

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
	:event_date=>"%A, %B %d, %Y at %I:%M %p",
	:time_date=>"%l:%M:%S %p on %A, %B %d, %Y",
	:tight=>"%Y/%b/%d %l:%M%p",
	:microformat=>"%Y-%b-%dT%H:%M:%S#{tzoff_negative ? '-' : '+'}#{sprintf("%02i:%02i", tzoff_hours, tzoff_minutes)}"
)

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
