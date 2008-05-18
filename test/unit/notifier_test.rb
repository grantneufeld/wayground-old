require File.dirname(__FILE__) + '/../test_helper'

class NotifierTest < ActionMailer::TestCase
	tests Notifier
	fixtures :users
	
	def test_signup_confirmation
		# WAYGROUND['SENDER']
		@expected.from = 'Wayground <wayground@wayground.ca>'
		@expected.to = '"Activate This" <activatethis@wayground.ca>'
		# WAYGROUND['TITLE_SHORT'] == 'WG'
		@expected.subject = '[WG] Please activate your new account'
		@expected.body    = read_fixture('signup_confirmation')
		@expected.date    = Time.now

		assert_equal @expected.encoded,
			Notifier.create_signup_confirmation(users(:activate_this),
				@expected.date).encoded
	end

	def test_activated
		@expected.from = 'Wayground <wayground@wayground.ca>'
		@expected.to = '"Login User" <login_test@wayground.ca>'
		@expected.subject = '[WG] Your account has been activated!'
		@expected.body    = read_fixture('activated')
		@expected.date    = Time.now

		assert_equal @expected.encoded,
			Notifier.create_activated(users(:login), @expected.date).encoded
	end
end
