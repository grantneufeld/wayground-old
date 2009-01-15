class CreateEvents < ActiveRecord::Migration
	def self.up
		create_table :events, :force=>true,
		:options=>'COMMENT="Events that users can attend." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :user, :null=>false
			t.belongs_to :editor
			t.belongs_to :group
			t.belongs_to :parent
			t.string :subpath, :null=>false
			t.datetime :next_at	# the next occurrence based on schedules
			t.datetime :over_at	# calc from schedules, nil means repeat with no end
			t.string :title, :null=>false
			t.string :description
			t.text :content
			t.string :content_type
			t.timestamps
		end
		change_table :events do |t|
			t.index [:user_id], :name=>'user'
			t.index [:parent_id], :name=>'parent'
			t.index [:subpath], :name=>'subpath', :unique=>true
			t.index [:next_at], :name=>'next_at'
			t.index [:over_at], :name=>'over_at'
			t.index [:title, :description], :name=>'text_info'
		end
		
		create_table :schedules, :force=>true,
		:options=>'COMMENT="Defines the dates, times and recurrence for events, and links locations to events." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :event, :null=>false
			t.datetime :start_at
			t.datetime :end_at
			t.string :recur	# '', relative, fixed, contained
			t.string :unit	# second minute hour day week month year
			t.integer :interval
			t.integer :ordinal	# x’th day of month, x’th week of year, … (-1 = last)
			t.string :recur_day	# '', Sunday, …, Saturday
			t.string :recur_month	# '', January, …, December
			t.text :info
			t.timestamps
		end
		change_table :schedules do |t|
			t.index [:event_id, :start_at], :name=>'event'
			t.index [:start_at], :name=>'start_at'
			t.index [:end_at], :name=>'end_at'
		end
		
		create_table :rsvps, :force=>true,
		:options=>'COMMENT="Links users to a schedules for events to specify their attendance." ENGINE=InnoDB CHARSET=utf8' do |t|
			t.belongs_to :schedule, :null=>false
			t.belongs_to :user, :null=>false
			t.integer :position
			t.string :rsvp, :null=>false # yes, no, maybe, invited
			t.datetime :confirmed_at
			t.timestamps
		end
		change_table :rsvps do |t|
			t.index [:schedule_id, :user_id], :name=>'oneperuser', :unique=>true
			t.index [:schedule_id, :position, :confirmed_at], :name=>'schedule'
			t.index [:user_id], :name=>'user'
			t.index [:rsvp], :name=>'rsvp'
		end
	end

	def self.down
		drop_table :rsvps
		drop_table :schedules
		drop_table :events
	end
end
