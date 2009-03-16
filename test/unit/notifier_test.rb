require File.dirname(__FILE__) + '/../test_helper'

class NotifierTest < ActionMailer::TestCase
	tests Notifier
	fixtures :users, :email_addresses, :recipients, :petitions, :signatures, :phone_messages
	
	def test_signup_confirmation
		# WAYGROUND['SENDER']
		@expected.from = 'Wayground <wayground@wayground.ca>'
		@expected.to = '"Activate This" <activatethis@wayground.ca>'
		# WAYGROUND['TITLE_SHORT'] == 'WG'
		@expected.subject = '[WG] Please activate your new account'
		@expected.body    = read_fixture('signup_confirmation')
		@expected.date    = Time.now

		assert_equal @expected.encoded,
			Notifier.create_signup_confirmation(email_addresses(:activate_this),
				@expected.date).encoded
	end

	def test_activated
		@expected.from = 'Wayground <wayground@wayground.ca>'
		@expected.to = '"Login User" <login_test@wayground.ca>'
		@expected.subject = '[WG] Your account has been activated'
		@expected.body    = read_fixture('activated')
		@expected.date    = Time.now

		assert_equal @expected.encoded,
			Notifier.create_activated(email_addresses(:login), @expected.date).encoded
	end
	
	def test_signature_confirmation
		@expected.from = 'Wayground <wayground@wayground.ca>'
		@expected.to = '"Confirm Signer User" <test+confirm_user@wayground.ca>'
		@expected.subject = "[WG] Petition signature confirmation: #{petitions(:update_petition).title}"
		@expected.body    = read_fixture('signature_confirmation')
		@expected.date    = Time.now

		assert_equal @expected.encoded,
			Notifier.create_signature_confirmation(petitions(:update_petition),
				signatures(:confirm_user), users(:admin),
				@expected.date).encoded
	end
	
	def test_email_message
		recipient = recipients(:one)
		from = 'Test From <from+test@wayground.ca>'
		subject = 'Test Email Message Subject'
		sent_at = Time.now
		content = "This is a test message.\n\nI hope it works."
		reply_to = 'Reply To <reply_to+test@wayground.ca>'
		
		@expected.to = recipient.to_s
		@expected.from = from
		@expected.subject = subject
		@expected.date = sent_at
		@expected.body = content
		@expected.reply_to = reply_to
		@expected['Errors-To'] = 'bounce@wayground.ca'
		
		assert_equal(@expected.encoded,
			Notifier.create_email_message({
				:recipient=>recipient, :from=>from, :reply_to=>reply_to,
				:subject=>subject, :content=>content, :sent_at=>sent_at}
			).encoded
		)
	end
	
	def test_email_message_from_nonlocal_domain
		recipient = recipients(:one)
		from = 'Test From <from+test@nonlocaldomain.tld>'
		subject = 'Test Email Message Subject'
		sent_at = Time.now
		content = "This is a test message.\n\nI hope it works."
		reply_to = 'Reply To <reply_to+test@wayground.ca>'
		
		@expected.to = recipient.to_s
		@expected.from = from
		@expected.subject = subject
		@expected.date = sent_at
		@expected.body = content
		@expected.reply_to = reply_to
		@expected['Return-Path'] = '<bounce@wayground.ca>'
		@expected['Sender'] = '<bounce@wayground.ca>'
		@expected['Errors-To'] = 'bounce@wayground.ca'
		
		assert_equal(@expected.encoded,
			Notifier.create_email_message({
				:recipient=>recipient, :from=>from, :reply_to=>reply_to,
				:subject=>subject, :content=>content, :sent_at=>sent_at}
			).encoded
		)
	end
	
	def test_email_message_from_bounce_address
		recipient = recipients(:one)
		from = 'Test Bounce <bounce@wayground.ca>'
		subject = 'Test Email Message Subject'
		sent_at = Time.now
		content = "This is a test message.\n\nI hope it works."
		reply_to = 'Reply To <reply_to+test@wayground.ca>'
		
		@expected.to = recipient.to_s
		@expected.from = from
		@expected.subject = subject
		@expected.date = sent_at
		@expected.body = content
		@expected.reply_to = reply_to
		
		assert_equal(@expected.encoded,
			Notifier.create_email_message({
				:recipient=>recipient, :from=>from, :reply_to=>reply_to,
				:subject=>subject, :content=>content, :sent_at=>sent_at}
			).encoded
		)
	end
	
	test "phone message with contact" do
		# Because the date gets printed in the body of the message,
		# need to set the time zone here so it doesn’t vary based on how other tests
		# have set it.
		Time.zone = 'UTC'
		message = phone_messages(:two)
		
		@expected.to = message.recipient.email
		@expected.from = message.posted_by.email
		@expected.subject = "Wayground Phone Message from #{message.contact.name}"
		@expected.date = message.created_at
		@expected.body = read_fixture('phone_message_with_contact')
		
		assert_equal(@expected.encoded,
			Notifier.create_phone_message(message, message.created_at).encoded
		)
	end
end
