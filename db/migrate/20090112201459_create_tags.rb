class CreateTags < ActiveRecord::Migration
	def self.up
		create_table :tags, :force=>true,
		:options=>'COMMENT="Keyword/phrase tagging (folksonomy) for any class of object." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :item, :polymorphic=>true
			t.belongs_to :user
			t.string :tag
			t.string :title
			t.timestamps
		end
		change_table :tags do |t|
			t.index [:item_type, :item_id, :tag], :name=>'item', :unique=>true
			t.index [:user_id], :name=>'user'
			t.index [:tag], :name=>'tag'
			t.index [:title], :name=>'title'
		end
	end

	def self.down
		drop_table :tags
	end
end
