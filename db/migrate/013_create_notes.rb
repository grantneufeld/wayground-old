class CreateNotes < ActiveRecord::Migration
	def self.up
		create_table :notes, :force=>true,
		:options=>'COMMENT="Text notes attached to any item." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :item, :polymorphic=>true
			t.belongs_to :user
			t.belongs_to :editor
			t.text :content
			t.timestamps
		end
		change_table :notes do |t|
			t.index [:item_type, :item_id, :created_at], :name=>'item'
			t.index [:user_id, :item_type, :created_at], :name=>'user'
		end
	end

	def self.down
		drop_table :notes
	end
end
