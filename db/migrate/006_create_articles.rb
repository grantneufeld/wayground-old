class CreateArticles < ActiveRecord::Migration
	def self.up
		say "Adding support for Article to the pages table"
		#add_column :pages, :type, :string, :default=>'Page', :null=>false
		execute "ALTER TABLE pages ADD COLUMN type char(255) FIRST"
		#add_column :pages, :author, :string
		execute "ALTER TABLE pages ADD COLUMN author char(255) AFTER editor_id"
		# issue is the publication volume, date or title (e.g., “Winter 2008”, “September 2007”, “Volume 12, Number 6”)
		#add_column :pages, :issue, :string
		execute "ALTER TABLE pages ADD COLUMN issue char(255) AFTER subpath"
		add_column :pages, :published_on, :date
		
		change_table :pages do |t|
			t.index [:type], :name=>'type'
			t.index [:author], :name=>'author'
			t.index [:issue], :name=>'issue'
			t.index [:published_on], :name=>'published_on'
		end
	end

	def self.down
		say "Removing support for Article from the pages table"
		execute "ALTER TABLE pages DROP INDEX published_on"
		remove_column :pages, :published_on
		execute "ALTER TABLE pages DROP INDEX issue"
		remove_column :pages, :issue
		execute "ALTER TABLE pages DROP INDEX author"
		remove_column :pages, :author
		execute "ALTER TABLE pages DROP INDEX type"
		remove_column :pages, :type
	end
end
