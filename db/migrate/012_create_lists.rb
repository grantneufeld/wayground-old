class CreateLists < ActiveRecord::Migration
	def self.up
		create_table :lists, :force=>true,
		:options=>'COMMENT="Allows users to save their own custom lists of items." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user, :null=>false
			t.string :title
			t.boolean :is_public, :default=>false
			t.timestamps
		end
		change_table :lists do |t|
			t.index [:user_id, :title], :name=>'user', :unique=>true
		end
		
		create_table :listitems, :force=>true,
		:options=>'COMMENT="Items for custom lists." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :item, :null=>false, :polymorphic=>true
			t.belongs_to :user, :null=>false
			t.string :title
			t.timestamps
		end
		change_table :listitems do |t|
			t.index [:item_type, :item_id], :name=>'item'
			t.index [:user_id, :item_type, :item_id], :name=>'user'
			t.index [:user_id, :title, :item_type, :item_id], :name=>'title', :unique=>true
		end
	end

	def self.down
		drop_table :listitems
		drop_table :lists
	end
end
