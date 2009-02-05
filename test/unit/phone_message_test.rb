require 'test_helper'

class PhoneMessageTest < ActiveSupport::TestCase
	fixtures :phone_messages, :users
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	
	
	# CLASS METHODS
	
	test "default include" do
		assert_equal [:owner, :contact], PhoneMessage.default_include
	end
	
	test "default order" do
		assert_equal 'phone_messages.created_at DESC', PhoneMessage.default_order
	end
	test "default order with recent" do
		assert_equal 'phone_messages.updated_at DESC, phone_messages.created_at DESC',
			PhoneMessage.default_order({:recent=>true})
	end
	
	test "search conditions" do
		assert_nil PhoneMessage.search_conditions
	end
	test "search conditions with custom params" do
		assert_equal ['a AND b',1,2], PhoneMessage.search_conditions({}, ['a','b'], [1,2])
	end
	test "search conditions with owner" do
		assert_equal ['phone_messages.owner_id = ?', users(:login).id],
			PhoneMessage.search_conditions({:owner=>users(:login)})
	end
	test "search conditions with contact" do
		assert_equal ['phone_messages.contact_id = ?', users(:login).id],
			PhoneMessage.search_conditions({:contact=>users(:login)})
	end
	test "search conditions with status" do
		assert_equal ['phone_messages.status = ?', 'open'],
			PhoneMessage.search_conditions({:status=>'open'})
	end
	test "search conditions with source" do
		assert_equal ['phone_messages.source = ?', 'phone'],
			PhoneMessage.search_conditions({:source=>'phone'})
	end
	test "search conditions with category" do
		assert_equal ['phone_messages.category = ?', 'test'],
			PhoneMessage.search_conditions({:category=>'test'})
	end
	test "search conditions with key" do
		assert_equal ['(phone_messages.category like ? OR phone_messages.phone like ? OR phone_messages.content like ?)',
			'%keyword%', '%keyword%', '%keyword%'],
			PhoneMessage.search_conditions({:key=>'keyword'})
	end
	test "search conditions with all params" do
		assert_equal ['a AND b AND phone_messages.owner_id = ?' +
			' AND phone_messages.contact_id = ? AND phone_messages.status = ?' +
			' AND phone_messages.source = ? AND phone_messages.category = ?' +
			' AND (phone_messages.category like ? OR phone_messages.phone like ? OR phone_messages.content like ?)',
			1, 2, users(:login).id, users(:login).id, 'open', 'phone', 'test',
			'%keyword%', '%keyword%', '%keyword%'],
		PhoneMessage.search_conditions(
			{:owner=>users(:login), :contact=>users(:login), :status=>'open', :source=>'phone', :category=>'test', :key=>'keyword'}, ['a','b'], [1,2])
	end
	
	
	# INSTANCE METHODS
	
	test "css class" do
		assert_equal 'phonemessage', phone_messages(:one).css_class
	end
	test "css class with prefix" do
		assert_equal 'dir-phonemessage', phone_messages(:two).css_class('dir-')
	end
	
	test "description" do
		assert_equal "#{phone_messages(:one).status}: #{phone_messages(:one).category}",
			phone_messages(:one).description
	end
	
	test "link" do
		assert_equal phone_messages(:one), phone_messages(:one).link
	end
	
	test "title" do
		assert_equal "For #{users(:staff).nickname}; From #{phone_messages(:one).phone}",
			phone_messages(:one).title
	end
	
	test "title prefix" do
		assert_equal phone_messages(:one).created_at.to_s(:tight),
			phone_messages(:one).title_prefix
	end
end
