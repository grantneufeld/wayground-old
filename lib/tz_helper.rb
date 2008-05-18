# Timezone Handling
module TzHelper
	protected

	def timezone_local
		# TODO: future: eventually support user-specific timezones
		@tz_helper_local_tz ||= TZInfo::Timezone.get WAYGROUND['DEFAULT_TIMEZONE']
	end
	def timezone_local_str
		@tz_helper_local_str ||= timezone_local.strftime "%Z"
	end

	# convert from a utc time/date to whatever is the local time
	def time_to_local(t)
		timezone_local.utc_to_local t
	end
	# convert to utc time/date from whatever is the local time
	def time_to_utc(t)
		timezone_local.utc_to_local t
	end

	# return a formatted datetime string
	def format_utc_datetime(t, format=:default, showtz=false)
		# convert from utc
		t = time_to_local t
		if format.is_a? String
			t.strftime format
		elsif format.is_a? Symbol
			case format
			when :default
				t.strftime "%a, %b %e, %Y, %l:%M %p" + (showtz ? " #{timezone_local_str}" : '')
			when :long
				t.strftime "%A, %B %e, %Y, %l:%M %p" + (showtz ? " #{timezone_local_str}" : '')
			when :long
				t.strftime "%B %e, %Y, %l:%M %p" + (showtz ? " #{timezone_local_str}" : '') # long without weekday
			when :short
				t.strftime "%Y/%m/%d %H:%M" + (showtz ? "#{timezone_local_str}" : '')
			when :tight
				t.strftime "%Y/%b/%d %l:%M%p" + (showtz ? " #{timezone_local_str}" : '')
			else
				t
			end
		else
			t
		end
	end
	# return a formatted date string
	def format_utc_date(t, format=:default, showtz=false)
		# convert from utc
		t = time_to_local t
		if format.is_a? String
			t.strftime format
		elsif format.is_a? Symbol
			case format
			when :default
				t.strftime "%a, %b %e, %Y"
			when :long
				t.strftime "%A, %B %e, %Y"
			when :simple
				t.strftime "%B %e, %Y" #long without weekday
			when :short
				t.strftime "%Y/%m/%d"
			when :tight
				t.strftime "%Y/%b/%d"
			else
				t
			end
		else
			t
		end
	end
	# return a formatted time string
	def format_utc_time(t, format=:default, showtz=false)
		# convert from utc
		t = time_to_local t
		if format.is_a? String
			t.strftime format
		elsif format.is_a? Symbol
			if format == :simple
				# no simple format for times
				format = :long
			end
			case format
			when :default
				t.strftime "%l:%M %p" + (showtz ? " #{timezone_local_str}" : '')
			when :long
				# "%I:%M %p"
				t.strftime "%l:%M %p" + (showtz ? " #{timezone_local_str}" : '')
			when :short
				t.strftime "%H:%M" + (showtz ? "#{timezone_local_str}" : '')
			when :tight
				t.strftime "%l:%M%p" + (showtz ? " #{timezone_local_str}" : '')
			else
				t
			end
		else
			t
		end
	end
end