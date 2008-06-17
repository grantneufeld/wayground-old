class CreatePaths < ActiveRecord::Migration
	def self.up
		create_table :paths do |t|
			t.integer :item_id
			t.string :item_type
			t.string :sitepath, :null=>false
			t.text :redirect
		end
		add_index :paths, [:item_id, :item_type], :name=>'item'
		add_index :paths, :sitepath, :name=>'sitepath'
		# create path objects for every existing page
		say "Migrating sitepaths from pages table to new paths table"
		execute "INSERT INTO paths (item_id, item_type, sitepath)
			SELECT pages.id, 'Page', pages.sitepath FROM pages ORDER BY pages.id"
		# remove the sitepath column from the pages table
		execute "ALTER TABLE pages DROP INDEX sitepath"
		remove_column :pages, :sitepath
	end

	def self.down
		say "Restoring sitepaths from paths table to pages.sitepath"
		# Restore the sitepath column for pages
		#add_column :pages, :sitepath, :string
		execute "ALTER TABLE pages ADD COLUMN sitepath char(255) AFTER subpath"
		add_index :pages, :sitepath, :name=>'sitepath'
		# copy the path data back into the pages table’s sitepath column
		paths = Path.find(:all, :conditions=>'paths.item_type = "Page" AND paths.sitepath != "" AND paths.sitepath IS NOT NULL')
		paths.each do |path|
			execute "UPDATE pages SET pages.sitepath='#{path.sitepath}' WHERE pages.id = #{path.item_id}"
		end
		
		drop_table :paths
	end
end
