class CreateLocations < ActiveRecord::Migration
	def self.up
		create_table :locations, :force=>true,
		:options=>'COMMENT="Address info." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.integer :locatable_id
			t.string :locatable_type
			t.integer :position, :null=>false, :default=>0
			t.string :name
			t.string :address
			t.string :address2
			t.string :city
			t.string :province
			t.string :country
			t.string :postal, :limit=>15
			t.string :longitude
			t.string :latitude
			t.string :url
			t.string :email
			# phone#_type is one of h=>home, w=>work, c=>cell, f=>fax, or blank
			t.string :phone1_type, :limit=>1
			t.string :phone1, :limit=>31
			t.string :phone2_type, :limit=>1
			t.string :phone2, :limit=>31
			t.string :phone3_type, :limit=>1
			t.string :phone3, :limit=>31

			t.timestamps
		end
		add_index :locations, [:locatable_type, :locatable_id, :position],
			:name=>'locatable'
		add_index :locations, [:name, :address], :name=>'name_address'
		add_index :locations, [:country, :province, :city],
			:name=>'country_province_city'
		add_index :locations, [:postal, :address], :name=>'postal_idx'
		add_index :locations, [:email], :name=>'email_idx'
		
		remove_column :users, :location
	end

	def self.down
		add_column :users, :location, :string
		
		drop_table :locations
	end
end
