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
		# create path objects for every existing item
		say "Migrating sitepaths from items table to new paths table"
		execute "INSERT INTO paths (show_id, show_type, sitepath)
			SELECT items.id, 'Item', items.sitepath FROM items ORDER BY items.id"
		# remove the sitepath column from the items table
		execute "ALTER TABLE items DROP INDEX sitepath"
		remove_column :items, :sitepath
	end

	def self.down
		# Restore the sitepath column for items
		say "Restoring sitepaths from paths table to items.sitepath"
		#add_column :items, :sitepath, :text
		execute "ALTER TABLE items ADD COLUMN sitepath TEXT AFTER subpath"
		execute "ALTER TABLE items ADD INDEX sitepath (sitepath(255))"
		# copy the path data back into the items table’s sitepath column
		paths = Path.find(:all, :conditions=>'paths.show_type = "Item" AND paths.sitepath != "" AND paths.sitepath IS NOT NULL')
		paths.each do |path|
			execute "UPDATE items SET items.sitepath='#{path.sitepath}' WHERE items.id = #{path.show_id}"
		end
		
		drop_table :paths
	end
end
