class CreateItems < ActiveRecord::Migration
	def self.up
		create_table :items, :force=>true,
		:options=>'COMMENT="Core data object." ENGINE=InnoDB CHARSET=utf8' do |t|
			# Magic Field Name for polymorphic tables:
			#t.string :type, :limit=>31, :null=>false
			# USERS
			t.integer :user_id # owner
			t.integer :editor_id # last editor
			# CONTAINMENT
			t.integer :parent_id
			t.string :subpath
			t.text :sitepath
			# CONTENT
			t.string :title
			t.string :description
			t.column :content, :longtext
			t.string :content_type
			#t.column :content_rendered, :longtext # pre-rendered content
			#t.text :url
			t.string :keywords
			#t.text :notes
			
			# IMPORTANT NOTE:
			# Update the method Item.find_for_listing whenever there are
			# changes to the fields of this table.

			t.timestamps
		end
		add_index :items, [:user_id, :title], :name=>'user'
		add_index :items, [:parent_id, :title], :name=>'parent'
		add_index :items, [:title, :content_type], :name=>'title'
		# can’t add regular indexes for text fields in MySQL,
		# must truncate to max 255 bytes
		execute "ALTER TABLE items ADD INDEX sitepath (sitepath(255))"
		
		# ======================================================== #
		# Create standard items for the site

		# Root Document
		say "Creating root document ('home page' Item)"
		Item.reset_column_information
		root_document = Item.new(:subpath=>'/', :title=>'Home Page',
			:content=>'Login as an administrative user to be able to edit this page.',
			:content_type=>'text/plain')
		root_document.set_sitepath!
		root_document.save!
		# Fudge the creator User.
		# The first user created will end up owning the standard items
		execute "UPDATE items SET user_id=1"
	end

	def self.down
		drop_table :items
	end
end
