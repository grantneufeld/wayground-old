class CreateDocuments < ActiveRecord::Migration
	def self.up
		create_table :db_files, :force=>true,
		:options=>'COMMENT="attachment_fu database file storage." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.binary :data, :limit=>200.megabytes
		end
		
		create_table :documents, :force=>true,
			:options=>'COMMENT="Metadata for files." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.integer :db_file_id
			t.integer :user_id, :null=>false
			t.integer :parent_id
			t.string :type
			t.string :subfolder
			t.string :content_type, :null=>false
			t.string :filename, :null=>false
			t.string :thumbnail
			t.integer :size, :null=>false
			t.integer :width
			t.integer :height

			t.timestamps
		end
		add_index :documents, :user_id
		add_index :documents, :parent_id
		add_index :documents, [:type, :thumbnail, :user_id], :name=>'type'
		add_index :documents, :filename, :name=>'filename'
		add_index :documents, [:thumbnail, :type, :user_id], :name=>'thumbnail'
		add_index :documents, :size
		add_index :documents, :created_at
		add_index :documents, [:thumbnail, :type, :filename],
		 	:name=>'thumbnail_filename'
		add_index :documents, [:type, :thumbnail, :filename],
		 	:name=>'type_filename'
	end

	def self.down
		drop_table :documents
		drop_table :db_files
	end
end
