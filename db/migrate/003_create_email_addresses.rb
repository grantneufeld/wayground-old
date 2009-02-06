class CreateEmailAddresses < ActiveRecord::Migration
	def self.up
		create_table :email_addresses, :force=>true,
		:options=>'COMMENT="Additional, secondary, email addresses for users." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user
			t.integer :position, :null=>false, :default=>0
			t.string :email, :null=>false
			t.string :activation_code, :limit=>40
			t.datetime :activated_at
			t.string :name
			t.timestamps
		end
		change_table :email_addresses do |t|
			t.index [:user_id, :position], :name=>'user'
			t.index [:email, :user_id], :name=>'email'
			t.index [:activated_at, :activation_code], :name=>':activation'
			t.index [:name], :name=>'name'
		end
	end

	def self.down
		drop_table :email_addresses
	end
end
