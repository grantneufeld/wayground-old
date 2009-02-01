class CreateListitems < ActiveRecord::Migration
	def self.up
		create_table :listitems, :force=>true,
		:options=>'COMMENT="Allows users to save their own custom lists of items." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :item, :polymorphic=>true
			t.belongs_to :user
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
	end
end
