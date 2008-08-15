class CreateMemberships < ActiveRecord::Migration
	def self.up
		create_table :memberships, :force=>true,
		:options=>'COMMENT="Links Users to Groups." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :group
			t.integer :position # order members within the group
			t.belongs_to :user
			t.belongs_to :location
			t.boolean :is_admin
			t.boolean :can_add_event
			t.boolean :can_invite
			t.boolean :can_moderate
			t.boolean :can_manage_members
			t.datetime :expires_at
			t.datetime :invited_at
			t.belongs_to :inviter
			t.datetime :blocked_at
			t.datetime :block_expires_at
			t.belongs_to :blocker
			t.string :title
			t.timestamps
		end
		change_table :memberships do |t|
			t.index [:group_id, :user_id], :name=>'membership_group',
				:unique=>true
			t.index [:group_id, :position, :user_id], :name=>'membership_position'
			t.index [:user_id, :group_id], :name=>'membership_user'
			t.index [:group_id, :invited_at], :name=>'membership_invitation'
			t.index [:group_id, :blocked_at], :name=>'membership_blocked'
			t.index [:group_id, :title, :user_id], :name=>'membership_title'
		end
	end

	def self.down
		drop_table :memberships
	end
end
