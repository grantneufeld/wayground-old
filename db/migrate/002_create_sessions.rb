class CreateSessions < ActiveRecord::Migration
	def self.up
		create_table :sessions, :force=>true,
		:options=>'COMMENT="User sessions." CHARSET=utf8' do |t|
			t.string :session_id, :null=>false
			t.text :data
			t.timestamps
		end
		change_table :sessions do |t|
			t.index [:session_id], :name=>'session_id'
			t.index [:updated_at], :name=>'updated_at'
		end
	end

	def self.down
		drop_table :sessions
	end
end
