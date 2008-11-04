class CreatePetitions < ActiveRecord::Migration
	def self.up
		create_table :petitions, :force=>true,
		:options=>'COMMENT="Petitions that users can sign." ENGINE=InnoDB CHARSET=utf8' do |t|
			# TODO: support petitions being ‘owned’ by a Group
			t.string :subpath # unique
			# who ‘owns’ the petition (who can admin it, view sigs, etc.)
			t.belongs_to :user
			# the period during which the petition may be signed
			t.datetime :start_at, :end_at
			# whether to show signatures on the web; whether to allow signers to add their own comments
			t.boolean :public_signatures, :allow_comments
			# the target number of signatures
			t.integer :goal
			t.string :title # unique
			# short description of the petition; used when listing petitions
			t.string :description
			# label for a field the signer’s fill in when signing
			t.string :custom_field_label
			# which region (if any) to restrict the petition signers to
			t.string :country_restrict, :province_restrict, :city_restrict
			# description of restrictions on who should sign
			t.string :restriction_description
			# the actual petition content (“whereas”, “we call on”, etc.)
			t.text :content
			# message shown to user after signing the petition
			t.text :thanks_message
			t.timestamps
		end
		change_table :petitions do |t|
			t.index [:subpath], :name=>'subpath', :unique=>true
			t.index [:user_id, :title], :name=>'user'
			t.index [:user_id, :start_at], :name=>'user_by_date'
			t.index [:title], :name=>'title', :unique=>true
		end
		
		create_table :signatures, :force=>true,
		:options=>'COMMENT="User signatures for Petitions." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :petition
			t.belongs_to :user # optional. If set, [petiton, user] must be unique
			# whether to show the name in public list of signatures, or ‘anonymous’
			t.boolean :is_public
			# whether the signatory wants followup contact or not
			t.boolean :allow_followup
			t.string :name
			t.string :email, :confirmation_code
			t.datetime :confirmed_at
			t.string :phone, :address, :city, :province, :country, :postal_code
			t.string :custom_field
			t.text :comment
			t.timestamps
		end
		change_table :signatures do |t|
			t.index [:petition_id, :email], :name=>'petition_email', :unique=>true
			t.index [:petition_id, :user_id, :is_public], :name=>'petition_user'
			t.index [:user_id, :petition_id], :name=>'user_petition'
			t.index [:confirmation_code], :name=>'confirmation_code'
		end
	end

	def self.down
		drop_table :signatures
		drop_table :petitions
	end
end
