class CreatePaths < ActiveRecord::Migration
	def self.up
		create_table :paths do |t|
			t.integer :show_id
			t.string :show_type
			t.text :sitepath, :null=>false
			t.text :redirect
		end
		add_index :paths, [:show_id, :show_type], :name=>'show'
		# can’t add regular indexes for text fields in MySQL,
		# must truncate to max 255 bytes
		execute "ALTER TABLE paths ADD INDEX sitepath (sitepath(255))"
		# create path objects for every existing page
		say "Migrating sitepaths from pages table to new paths table"
		execute "INSERT INTO paths (show_id, show_type, sitepath)
			SELECT pages.id, 'Page', pages.sitepath FROM pages ORDER BY pages.id"
		# remove the sitepath column from the pages table
		execute "ALTER TABLE pages DROP INDEX sitepath"
		remove_column :pages, :sitepath
	end

	def self.down
		# Restore the sitepath column for pages
		say "Restoring sitepaths from paths table to pages.sitepath"
		#add_column :pages, :sitepath, :text
		execute "ALTER TABLE pages ADD COLUMN sitepath TEXT AFTER subpath"
		execute "ALTER TABLE pages ADD INDEX sitepath (sitepath(255))"
		# copy the path data back into the pages table’s sitepath column
		paths = Path.find(:all, :conditions=>'paths.show_type = "Page" AND paths.sitepath != "" AND paths.sitepath IS NOT NULL')
		paths.each do |path|
			execute "UPDATE pages SET pages.sitepath='#{path.sitepath}' WHERE pages.id = #{path.show_id}"
		end
		
		drop_table :paths
	end
end
