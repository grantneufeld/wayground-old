class CreateGroups < ActiveRecord::Migration
	def self.up
		create_table :groups, :force=>true,
		:options=>'COMMENT="Groups of users/contacts." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :parent	# groups.parent_id = groups.id
			t.belongs_to :creator	# groups.creator_id = users.id
			t.belongs_to :owner		# groups.owner_id = users.id
			t.boolean :is_visible	# the group will show up in public lists
			t.boolean :is_public	# group content can be seen by non-members
			t.boolean :is_members_visible	# users can see who is in the group
			t.boolean :is_invite_only	# only group admins can add members
			t.boolean :is_no_unsubscribe	# users can’t remove themselves
			t.string :subpath
			t.string :name
			t.string :url
			t.text :description
			t.text :welcome	# welcome message for newly signed-up members
			t.timestamps
		end
		change_table :groups do |t|
			t.index [:subpath], :name=>'group_subpath', :unique=>true
			t.index [:name], :name=>'group_name', :unique=>true
			t.index [:name, :is_visible], :name=>'group_name_visible'
			t.index [:parent_id, :is_visible, :name],
				:name=>'group_parent'
			t.index [:creator_id, :is_visible, :name],
				:name=>'group_creator'
			t.index [:owner_id, :is_visible, :name], :name=>'group_owner'
		end
	end

	def self.down
		drop_table :groups
	end
end
