require 'test_helper'

class EmailMessageTest < ActiveSupport::TestCase
	fixtures :email_messages, :users, :groups, :recipients, :attachments
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	
	
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
	
	test "css class" do
		assert_equal 'email', email_messages(:one).css_class
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
