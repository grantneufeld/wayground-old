class CreateMessaging < ActiveRecord::Migration
	def self.up
		create_table :email_messages, :force=>true,
		:options=>'COMMENT="Email message sent to one or more recipients." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user
			t.belongs_to :item, :polymorphic=>true
			t.string :status, :null=>false, :default=>'draft' # %w(draft sent)
			t.string :from
			t.string :to
			t.string :subject
			t.string :content_type
			t.text :content
			t.timestamps # updated_at == sent_at
		end
		change_table :email_messages do |t|
			t.index [:item_type, :item_id, :created_at], :name=>'item'
			t.index [:user_id, :created_at], :name=>'user'
		end
		
		create_table :phone_messages, :force=>true,
		:options=>'COMMENT="Message recorded by one User for another." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user
			t.belongs_to :owner
			t.belongs_to :contact
			t.string :status # %w(open read closed)
			t.string :source # %w(phone email fax walk-in)
			t.string :category
			t.string :phone
			t.text :content
			t.timestamps
		end
		change_table :phone_messages do |t|
			t.index [:user_id, :created_at], :name=>'user'
			t.index [:owner_id, :status, :category, :created_at], :name=>'owner'
			t.index [:contact_id, :source, :status, :created_at], :name=>'contact'
			t.index [:status, :category, :created_at], :name=>'status'
			t.index [:category, :status, :created_at], :name=>'category'
		end
		
		create_table :recipients, :force=>true,
		:options=>'COMMENT="Links an EmailAddress, as a recipient, to an EmailMessage." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :email_message
			t.belongs_to :email_address
			t.datetime :created_at
			t.datetime :last_send_attempt_at
			t.datetime :sent_at
			#t.timestamps
		end
		change_table :recipients do |t|
			t.index [:email_message_id, :email_address_id], :name=>'email_message',
				:unique=>true
			t.index [:email_address_id], :name=>'email_address'
			t.index [:last_send_attempt_at], :name=>'last_send_attempt'
		end
		
		create_table :attachments, :force=>true,
		:options=>'COMMENT="Links a Document to an EmailMessage." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :email_message
			t.belongs_to :document
			t.integer :position
			t.timestamps
		end
		change_table :attachments do |t|
			t.index [:email_message_id, :position], :name=>'email_message'
			t.index [:document_id, :created_at], :name=>'document'
		end
	end

	def self.down
		drop_table :attachments
		drop_table :recipients
		drop_table :phone_messages
		drop_table :email_messages
	end
end
