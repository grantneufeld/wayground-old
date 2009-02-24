class CreateUsers < ActiveRecord::Migration
	def self.up
		# ======================================================== #
		# USERS
		create_table :users, :force=>true,
		:options=>'COMMENT="Basic user record for login." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.string :email
			# email activation
			#t.string :activation_code, :limit=>40
			#t.datetime :activated_at
			
			# Password
			t.string :crypted_password, :limit=>40
			t.string :salt, :limit=>40
			
			# Identity
			t.string :nickname # screen name
			t.string :fullname, :null=>false
			
			# Access flags
			t.boolean :admin, :staff
			
			# Remember user across sessions
			t.string :remember_token
			t.datetime :remember_token_expires_at
			
			# user subpath for non-numeric urls
			t.string :subpath, :limit=>31
			t.string :time_zone
			# the user's personal description for their profile
			t.text :about
			
			# has_many counters
			#t.integer :messages_count, :default=>0
			
			t.datetime :login_at
			t.timestamps
			#t.integer :lock_version, :default=>0, :null=>false
		end
		change_table :users do |t|
			t.index [:email], :name=>'email', :unique=>true
			t.index [:nickname], :name=>'nickname', :unique=>true
			t.index [:fullname], :name=>'fullname'
			t.index [:staff, :nickname], :name=>'staff'
			t.index [:remember_token], :name=>'remember_token', :unique=>true
			t.index [:subpath], :name=>'subpath' #, :unique=>true - allows null
		end
		
		# TODO: OpenID support
		# TODO: Facebook Connect support
		
		# TODO ••• add Foreign Key Constraints: http://dev.mysql.com/doc/refman/5.0/en/innodb-foreign-key-constraints.html
	end

	def self.down
		drop_table :users
	end
end
