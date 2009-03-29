class CreateLists < ActiveRecord::Migration
	def self.up
		create_table :lists, :force=>true,
		:options=>'COMMENT="Allows users to save their own custom lists of items." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user, :null=>false # owner of the List
			t.string :title, :null=>false # name of the List
			t.boolean :is_public, :null=>false, :default=>false # if false, only User (owner) can see it
			t.timestamps
		end
		change_table :lists do |t|
			t.index [:user_id, :title], :name=>'user', :unique=>true
		end
		
		create_table :listitems, :force=>true,
		:options=>'COMMENT="Items for custom lists." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :list, :null=>false
			t.belongs_to :item, :null=>false, :polymorphic=>true
			#t.belongs_to :user, :null=>false # User who added this item to the List
			t.integer :position, :null=>false
			t.timestamps
		end
		change_table :listitems do |t|
			t.index [:list_id, :position], :name=>'list'
			t.index [:item_type, :item_id], :name=>'item'
		end
	end

	def self.down
		drop_table :listitems
		drop_table :lists
	end
end
