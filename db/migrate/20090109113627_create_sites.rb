class CreateSites < ActiveRecord::Migration
	def self.up
		create_table :sites, :force=>true,
		:options=>'COMMENT="Websites hosted by this system." ENGINE=InnoDB CHARSET=utf8' do |t|
			# the basic domain of the site. E.g., ‘www.mysite.tld’
			t.string :domain
			# the root url of the site
			t.string :url
			# the local file system path to the public root for the site
			t.string :path
			# the name of the layout file, without file extension to use.
			# E.g., ‘admin’ for ‘admin.html.erb’
			t.string :layout
			# the full title of the website
			t.string :title
			# the prefix to use in front of page titles in the <title> element.
			t.string :title_prefix
			# the email address to send notices from the site from.
			t.string :email
			# the name to send notices from (as in “sender <email>”).
			t.string :sender
			
			t.timestamps
		end
		change_table :sites do |t|
			t.index [:domain], :name=>'domain', :unique=>true
			t.index [:url], :name=>'url', :unique=>true
			t.index [:path], :name=>'path', :unique=>true
		end
	end

	def self.down
		drop_table :sites
	end
end
