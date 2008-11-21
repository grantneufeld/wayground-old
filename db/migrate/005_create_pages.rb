class CreatePages < ActiveRecord::Migration
	def self.up
		create_table :pages, :force=>true,
		:options=>'COMMENT="Core data object." ENGINE=InnoDB CHARSET=utf8' do |t|
			# Magic Field Name for polymorphic tables:
			#t.string :type, :limit=>31, :null=>false
			# USERS
			t.integer :user_id # owner
			t.integer :editor_id # last editor
			# CONTAINMENT
			t.integer :parent_id
			t.string :subpath
			t.string :sitepath
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
			# Update the method Page.find_for_listing whenever there are
			# changes to the fields of this table.

			t.timestamps
		end
		add_index :pages, [:user_id, :title], :name=>'user'
		add_index :pages, [:parent_id, :title], :name=>'parent'
		add_index :pages, [:title, :content_type], :name=>'title'
		add_index :pages, :sitepath, :name=>'sitepath'
		
		# ======================================================== #
		# Create standard pages for the site

		# Root Document
		say "Creating root document ('home page' Page)"
		execute 'INSERT INTO pages SET user_id=1, ' \
			'subpath="/", sitepath="/", title="Home Page", ' \
			'content="Login as an administrator to be able to edit this page.", ' \
			'content_type="text/plain", ' \
			'created_at=UTC_TIMESTAMP(), updated_at=UTC_TIMESTAMP();'
	end

	def self.down
		drop_table :pages
	end
end
