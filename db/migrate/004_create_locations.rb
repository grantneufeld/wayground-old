class CreateLocations < ActiveRecord::Migration
	def self.up
		create_table :locations, :force=>true,
		:options=>'COMMENT="Address info." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :locatable, :polymorphic=>true
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
		#	t.string :email
			# phone#_type is one of h=>home, w=>work, c=>cell, f=>fax, or blank
			t.string :phone1_type, :limit=>1
			t.string :phone1, :limit=>31
			t.string :phone2_type, :limit=>1
			t.string :phone2, :limit=>31
			t.string :phone3_type, :limit=>1
			t.string :phone3, :limit=>31
			t.timestamps
		end
		change_table :locations do |t|
			t.index [:locatable_type, :locatable_id, :position], :name=>'locatable'
			t.index [:name, :address], :name=>'name_address'
			t.index [:country, :province, :city], :name=>'country_province_city'
			t.index [:postal, :address], :name=>'postal_idx'
		end
	end

	def self.down
		drop_table :locations
	end
end
