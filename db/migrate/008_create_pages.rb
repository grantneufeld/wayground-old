class CreatePages < ActiveRecord::Migration
	def self.up
		create_table :pages, :force=>true,
		:options=>'COMMENT="Core data object." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.string :type, :default=>'Page', :null=>false
			# CONTAINMENT
			t.belongs_to :site
			t.belongs_to :parent
			t.string :subpath, :null=>false
			# USERS
			t.belongs_to :user # owner
			t.belongs_to :editor # last editor
			# CONTENT
			t.string :title
			# publication volume, date or title (e.g., “Winter 2008”, “Volume 12, Number 6”)
			t.string :issue # Article
			t.string :author # Article
			t.string :description
			t.column :content, :longtext
			t.string :content_type
			#t.column :content_rendered, :longtext # pre-rendered content
			#t.text :url
			t.string :keywords

			t.date :published_on
			t.timestamps
		end
		change_table :pages do |t|
			t.index [:type, :title], :name=>'type'
			t.index [:site_id, :parent_id, :subpath], :name=>'site_path', :unique=>true
			t.index [:parent_id, :subpath], :name=>'parent_path', :unique=>true
			t.index [:user_id, :title], :name=>'user'
			t.index [:site_id, :parent_id, :title], :name=>'site'
			t.index [:parent_id, :title], :name=>'parent'
			t.index [:title, :content_type], :name=>'title'
			t.index [:issue], :name=>'issue'
			t.index [:author], :name=>'author'
			t.index [:published_on], :name=>'published_on'
		end
		
		create_table :paths do |t|
			t.belongs_to :site
			t.belongs_to :item, :polymorphic=>true
			t.string :sitepath, :null=>false
			t.text :redirect
		end
		change_table :paths do |t|
			t.index [:site_id, :item_id, :item_type], :name=>'site_item'
			t.index [:site_id, :sitepath], :name=>'site_sitepath', :unique=>true
			t.index [:item_id, :item_type], :name=>'item'
			t.index [:sitepath, :site_id], :name=>'sitepath'
		end
		
		# ======================================================== #
		# Create standard root page for the site
		say "Creating root page ('Home Page')"
		# leave editor, site, parent, description and keywords null
		execute 'INSERT INTO pages SET id=1, user_id=1, ' \
			'subpath="/", title="Home Page", ' \
			'content="Login as an administrator to be able to edit this page.", ' \
			'content_type="text/plain", ' \
			'created_at=UTC_TIMESTAMP(), updated_at=UTC_TIMESTAMP();'
		# ======================================================== #
		# Create path for default root page
		say "Creating path for root page"
		# leave site and redirect null
		execute 'INSERT INTO paths SET id=1, item_id=1, item_type="Page", sitepath="/"'
	end

	def self.down
		drop_table :paths
		drop_table :pages
	end
end
