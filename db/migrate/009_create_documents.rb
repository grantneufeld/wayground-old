class CreateDocuments < ActiveRecord::Migration
	def self.up
		create_table :db_files, :force=>true,
		:options=>'COMMENT="attachment_fu database file storage." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.binary :data, :limit=>200.megabytes
		end
		
		create_table :documents, :force=>true,
			:options=>'COMMENT="Metadata for files." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.string :type, :null=>false
			t.integer :db_file_id
			t.belongs_to :user, :null=>false
			t.belongs_to :site
			t.belongs_to :parent
			t.string :content_type, :null=>false
			t.string :filename, :null=>false
			t.string :thumbnail
			t.integer :size, :null=>false
			t.integer :width
			t.integer :height

			t.timestamps
		end
		change_table :documents do |t|
			t.index [:user_id], :name=>'user'
			t.index [:parent_id], :name=>'parent'
			t.index [:site_id, :filename], :name=>'site'
			t.index [:type, :thumbnail, :filename], :name=>'type'
			t.index [:filename], :name=>'filename', :unique=>true
			t.index [:thumbnail, :type, :filename], :name=>'thumbnail'
			t.index [:size], :name=>'size'
			t.index [:created_at], :name=>'created_at'
		end
	end

	def self.down
		drop_table :documents
		drop_table :db_files
	end
end
