class CreateWeblinks < ActiveRecord::Migration
	def self.up
		create_table :weblinks, :force=>true,
		:options=>'COMMENT="Web links linked to other items." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user # the submitter of the weblink
			t.belongs_to :item, :polymorphic=>true
			t.boolean :is_confirmed # urls submitted by regular users need to be confirmed by a moderator/admin
			t.integer :position
			t.string :category
			t.string :title
			t.string :site # abbreviation of website for the link, primarily used for css rendering of the link with a site-specific icon
			t.text :url, :null=>false
			t.text :description

			t.timestamps
		end
		change_table :weblinks do |t|
			t.index [:item_id, :item_type, :category, :position, :title, :site],
				:name=>'weblink_item'
			t.index [:user_id, :item_id, :item_type, :category, :position, :title, :site],
				:name=>'weblink_user'
			t.index [:item_id, :item_type, :is_confirmed], :name=>'weblink_is_confirmed'
		end
	end

	def self.down
		drop_table :weblinks
	end
end
