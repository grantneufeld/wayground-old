class CreateEmailAddresses < ActiveRecord::Migration
	def self.up
		create_table :email_addresses, :force=>true,
		:options=>'COMMENT="Additional, secondary, email addresses for users." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user
			t.integer :position, :null=>false, :default=>0
			t.string :email, :null=>false
			t.string :activation_code, :limit=>40
			t.datetime :activated_at
			t.boolean :is_blocked
			t.string :name
			t.datetime :created_at
			#t.timestamps
		end
		change_table :email_addresses do |t|
			t.index [:email], :name=>'email', :unique=>true
			t.index [:user_id, :position], :name=>'user'
			t.index [:activation_code], :name=>':activation_code', :unique=>true
			t.index [:name], :name=>'name'
		end
	end

	def self.down
		drop_table :email_addresses
	end
end
