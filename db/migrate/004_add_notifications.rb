class AddNotifications < ActiveRecord::Migration
	def self.up
		# This is used by ar_mailer to store the outgoing email queue
		create_table :notifications, :force=>true,
			:options=>'COMMENT="Outbound email messages (ar_mailer)." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.string :from, :to
			t.integer :last_send_attempt, :default=>0
			t.text :mail
			t.timestamp :created_at
			#t.timestamps
		end
		add_index :notifications, :last_send_attempt
		add_index :notifications, :created_at
	end

	def self.down
		drop_table :notifications
	end
end
