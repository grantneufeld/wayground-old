class Site < ActiveRecord::Base
	attr_accessible :domain, :url, :path, :layout, :title, :title_prefix, :email, :sender
	
	LOCAL_DOMAINS = ['activism.ca', 'activist.ca', 'arusha.org', 'calgarydemocracy.ca', 'calgarydollars.ca', 'wayground.ca']
	
	validates_presence_of :layout
	validates_presence_of :title
	validates_presence_of :title_prefix
	validates_presence_of :email
	validates_presence_of :sender
	validates_uniqueness_of :domain
	validates_format_of :domain, :with=>/\A([a-z0-9\-]+\.)+[a-z0-9]+\z/
	validates_uniqueness_of :url
	validates_format_of :url, :with=>/\Ahttp:\/\/([a-z0-9\-]+\.)+[a-z0-9]+\/\z/
	validates_uniqueness_of :path
	validates_format_of :path,
	 	:with=>/\A([A-Za-z0-9_][A-Za-z0-9_\-]*\.)*[A-Za-z0-9_][A-Za-z0-9_\-]*\z/,
		:message=>"must point to a valid subdirectory"
	
	has_many :pages
	has_many :paths
	
	# Return an array of site arrays.
	# Used as a param for form select element generators.
	def self.select_list
		sites = self.find(:all, :order=>'sites.id')
		site_list = [[WAYGROUND['TITLE'], '']]
		sites.each do |s|
			site_list << [s.title, s.id]
		end
		site_list
	end
	
	# Returns true if the domain of the email address matches a domain considered
	# to be “local” to the server.
	def self.is_local_email?(email_address)
		LOCAL_DOMAINS.include?(
			email_address.match(/@([\w\.\-]+\.\w+)/)[1]
		)
	end
end
