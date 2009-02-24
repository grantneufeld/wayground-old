require 'test_helper'

class EmailMessageTest < ActiveSupport::TestCase
	fixtures :email_messages, :email_addresses, :users, :groups, :recipients, :attachments
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	test "minimum attributes to pass validation" do
		e = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca')
		e.user = users(:staff)
		assert_valid e
	end
	test "validation fails without user" do
		e = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca')
		assert_validation_fails_for(e, ['user'])
	end
	test "validation passes on sent status" do
		e = EmailMessage.new(:status=>'sent', :from=>'test@wayground.ca')
		e.user = users(:staff)
		assert_valid e
	end
	test "validation fails on invalid status" do
		e = EmailMessage.new(:status=>'invalid', :from=>'test@wayground.ca')
		e.user = users(:staff)
		assert_validation_fails_for(e, ['status'])
	end
	test "validation passes on extended from" do
		e = EmailMessage.new(:status=>'draft', :from=>'"Test User" <test@wayground.ca>')
		e.user = users(:staff)
		assert_valid e
	end
	test "validation fails without from" do
		e = EmailMessage.new(:status=>'draft')
		e.user = users(:staff)
		assert_validation_fails_for(e, ['from'])
	end
	test "validation fails on invalid from" do
		e = EmailMessage.new(:status=>'draft', :from=>'invalid')
		e.user = users(:staff)
		assert_validation_fails_for(e, ['from'])
	end
	test "validation passes on plain text content_type" do
		e = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca',
			:content_type=>'text/plain')
		e.user = users(:staff)
		assert_valid e
	end
	test "validation passes on html content_type" do
		e = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca',
			:content_type=>'text/html')
		e.user = users(:staff)
		assert_valid e
	end
	test "validation fails on invalid content_type" do
		e = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca',
			:content_type=>'invalid')
		e.user = users(:staff)
		assert_validation_fails_for(e, ['content_type'])
	end
	
	
	# ATTRIBUTES
	
	test "status defaults to 'draft'" do
		e = EmailMessage.new(:from=>'test@wayground.ca')
		e.user = users(:staff)
		assert_equal 'draft', e.status
	end
	
	
	# CLASS METHODS
	
	test "default include" do
		assert_equal [:user, :item], EmailMessage.default_include
	end
	
	test "default order" do
		assert_equal 'email_messages.subject', EmailMessage.default_order
	end
	test "default order with recent" do
		assert_equal 'email_messages.updated_at DESC, email_messages.subject',
			EmailMessage.default_order({:recent=>true})
	end
	
	test "search conditions" do
		assert_nil EmailMessage.search_conditions
	end
	test "search conditions with custom params" do
		assert_equal ['a AND b',1,2], EmailMessage.search_conditions({}, ['a','b'], [1,2])
	end
	test "search conditions with sender" do
		assert_equal ['email_messages.user_id = ?', users(:login).id],
			EmailMessage.search_conditions({:sender=>users(:login)})
	end
	test "search conditions with item" do
		assert_equal ['email_messages.item_id = ? AND email_messages.item_type = ?',
			groups(:one).id, 'Group'],
			EmailMessage.search_conditions({:item=>groups(:one)})
	end
	test "search conditions with key" do
		assert_equal ['(email_messages.subject like ? OR email_messages.to like ? OR email_messages.from like ?)',
			'%keyword%', '%keyword%', '%keyword%'],
			EmailMessage.search_conditions({:key=>'keyword'})
	end
	test "search conditions with all params" do
		assert_equal ['a AND b AND email_messages.user_id = ?' +
			' AND email_messages.item_id = ? AND email_messages.item_type = ?' +
			' AND (email_messages.subject like ? OR email_messages.to like ?' +
				' OR email_messages.from like ?)',
			1, 2, users(:login).id, groups(:one).id, 'Group',
			'%keyword%', '%keyword%', '%keyword%'],
		EmailMessage.search_conditions(
			{:sender=>users(:login), :item=>groups(:one), :key=>'keyword'}, ['a','b'], [1,2])
	end
	
	
	# INSTANCE METHODS
	
	test "has recipient email" do
		assert_equal(recipients(:one),
		 	recipients(:one).email_message.has_recipient_email(
				recipients(:one).email_address.email
			)
		)
	end
	test "does not have recipient email" do
		assert_nil email_messages(:one).has_recipient_email('not-have+test@wayground.ca')
	end
	
	test "add recipient" do
		r = email_messages(:one).add_recipient(email_addresses(:another))
		assert_equal email_messages(:one), r.email_message
		assert_equal email_addresses(:another), r.email_address
	end
	test "add recipient with custom email and name" do
		email = 'custom+test@wayground.ca'
		name = 'Custom Name'
		r = email_messages(:one).add_recipient(email_addresses(:another))
		assert_equal email_messages(:one), r.email_message
		assert_equal email_addresses(:another), r.email_address
	end
	test "do not add duplicate recipient email" do
		assert_nil email_messages(:one).add_recipient(email_addresses(:one))
	end
	
	test "initialize recipients with just custom to" do
		m = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca',
			:to=>'recipient+test@wayground.ca')
		m.user = users(:staff)
		m.initialize_recipients
		assert_equal 1, m.recipients.size
	end
	test "initialize recipients with self copy" do
		m = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca',
			:to=>'recipient+test@wayground.ca')
		m.user = users(:staff)
		m.self_copy = true
		m.initialize_recipients
		assert_equal users(:staff).email, m.recipients[1].email_address.email
	end
	test "initialize recipients with blocked address" do
		m = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca',
			:to=>email_addresses(:blocked).email)
		m.user = users(:staff)
		m.initialize_recipients
		assert_equal 0, m.recipients.size
	end
	test "initialize recipients with item" do
		m = EmailMessage.new(:status=>'draft', :from=>'test@wayground.ca',
			:to=>'recipient+test@wayground.ca')
		m.user = users(:staff)
		m.item = groups(:one)
		m.initialize_recipients
		#assert_equal 1, m.recipients.size
	end
	
	test "deliver" do
		assert email_messages(:one).deliver!
	end
	test "deliver with mailer error" do
		Notifier.stubs(:deliver_email_message).raises(Net::SMTPFatalError)
		assert_raise Wayground::DeliveryFailure do
			email_messages(:one).deliver!
		end	
		email_messages(:one).recipients.each do |recipient|
			assert_nil recipient.sent_at,
				"expected nil sent_at for recipient #{recipient.email_address.email}"
			assert !(recipient.last_send_attempt_at.blank?)	,
				"expected last_send_attempt_at to be set for recipient #{recipient.email_address.email}"
		end
	end
	
	test "blocked with none blocked" do
		assert_equal [], email_messages(:one).blocked
	end
	test "blocked with blocked addresses" do
		# TODO: test email_message.blocked with blocked addresses
	end
	
	test "self copy" do
		assert !(email_messages(:one).self_copy)
	end
	test "self copy assignment" do
		email_messages(:one).self_copy = true
		assert email_messages(:one).self_copy
	end
	
	test "css class for sent" do
		assert_equal 'emailsent', email_messages(:one).css_class
	end
	test "css class for draft" do
		assert_equal 'email', email_messages(:two).css_class
	end
	test "css class with prefix" do
		assert_equal 'dir-email', email_messages(:two).css_class('dir-')
	end
	
	test "description" do
		assert_nil email_messages(:one).description
	end
	
	test "link" do
		assert_equal email_messages(:one), email_messages(:one).link
	end
	
	test "title" do
		assert_equal email_messages(:one).subject, email_messages(:one).title
	end
	
	test "title prefix" do
		assert_equal email_messages(:one).updated_at.to_s(:tight),
			email_messages(:one).title_prefix
	end
end
