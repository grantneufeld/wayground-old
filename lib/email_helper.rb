# validation of email addresses
module EmailHelper
	require 'resolv'
	
	# Returns an error message if the domain cannot be found, nil if okay
	def domain_error(domain)
		begin
			Resolv::DNS.open do |dns|
				@mx = dns.getresources(domain.to_s, Resolv::DNS::Resource::IN::MX)
			end
			if @mx.empty?
				"domain name “#{domain}” can not be found."
			else
				nil
			end
		rescue
			"unable to resolve the domain name “#{domain}”"
		end
	end
	
	# returns the domain portion of an email address string
	def domain_of(email)
		domain = email.match /[^@]+\z/
		domain[0] if domain
	end
end