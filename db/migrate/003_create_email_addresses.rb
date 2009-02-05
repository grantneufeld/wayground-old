class CreateEmailAddresses < ActiveRecord::Migration
	def self.up
		create_table :email_addresses, :force=>true,
		:options=>'COMMENT="Additional, secondary, email addresses for users." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user
			t.integer :position
			t.string :email
			t.string :activation_code, :limit=>40
			t.datetime :activated_at
			t.string :name
			t.timestamps
		end
		change_table :email_addresses do |t|
			t.index [:user_id, :position], :name=>'user'
			t.index [:email], :name=>'email', :unique=>true
			t.index [:activated_at, :activation_code], :name=>':activation'
			t.index [:name], :name=>'name'
		end
	end

	def self.down
		drop_table :email_addresses
	end
end
