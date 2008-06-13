class CreateUsers < ActiveRecord::Migration
	def self.up
		# ======================================================== #
		# USERS
		create_table :users, :force=>true,
		:options=>'COMMENT="Basic user record for login." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.string :email
			# email activation
			t.string :activation_code, :limit=>40
			t.datetime :activated_at
			
			# Password
			t.string :crypted_password, :limit=>40
			t.string :salt, :limit=>40
			
			# Identity
			t.string :nickname # screen name
			t.string :fullname
			
			# Access flags
			t.boolean :admin, :staff
			
			# Remember user across sessions
			t.string :remember_token
			t.datetime :remember_token_expires_at
			
			
			t.string :subpath, :limit=>31
				# user subpath for non-numeric urls
			t.string :time_zone
			t.string :location
				# the user's community/city/province/country
			t.text :about
				# the user's personal description for their profile
			
			# has_many counters
			#t.integer :messages_count, :default=>0
			
			t.datetime :login_at
			t.timestamps
			#t.integer :lock_version, :default=>0, :null=>false
		end
		add_index :users, :email, :unique=>true
		add_index :users, :nickname, :unique=>true
		add_index :users, :staff
		add_index :users, :remember_token, :unique=>true
		add_index :users, :subpath, :unique=>true
		
		# ======================================================== #
		# EMAIL_CHANGES
		# Requests to change users’ email addresses
		create_table :email_changes, :force=>true,
		:options=>'COMMENT="Pending change email requests for users." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.integer :user_id
			t.string :email
			# email activation
			t.string :activation_code, :limit=>40
		end
		add_index :email_changes, :email, :unique=>true
		
		# ======================================================== #
		# OPENIDS
		
		# ======================================================== #
		# CONTACTS
		create_table :contacts, :force=>true,
		:options=>'COMMENT="Basic user record for login." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.integer :user_id, :null=>false
			t.integer :position, :null=>false, :default=>0
			
			t.string :locationtype, :limit=>63
				# 'home','work','school','postal','other',...
			t.string :preference, :default=>"", :null=>false
				# enum('','email','phone','postal','fax')
			
			t.string :organization, :jobtitle
			# Address
			t.string :address, :address2
			t.string :city, :province, :country, :postal
			# Phone
			t.string :phone1, :limit=>63
			t.string :phone1_type, :limit=>1 # '',h,w,c,f
			t.string :phone2, :limit=>63
			t.string :phone2_type, :limit=>1 # '',h,w,c,f
			t.string :phone3, :limit=>63
			t.string :phone3_type, :limit=>1 # '',h,w,c,f
			# Email
			# One email address per contact - used in the User record
			#t.string :email
			#t.string :activation_code, :limit=>40
			#t.datetime :activated_at
			
			t.timestamps
		end
		add_index :contacts, [:user_id, :position]
		add_index :contacts, [:country, :province, :city]
		
		# TODO ••• add Foreign Key Constraints: http://dev.mysql.com/doc/refman/5.0/en/innodb-foreign-key-constraints.html
	end

	def self.down
		drop_table :contacts
		drop_table :email_changes
		drop_table :users
	end
end
