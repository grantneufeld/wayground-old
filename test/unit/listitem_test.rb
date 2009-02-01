require 'test_helper'

class ListitemTest < ActiveSupport::TestCase
	fixtures :listitems, :pages, :users, :events
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	test "validation with all values set" do
		li = Listitem.new(:title=>'test1')
		li.item = pages(:one)
		li.user = users(:login)
		assert_valid li
	end
	test "validation fails in absence of item" do
		li = Listitem.new(:title=>'test2')
		li.user = users(:login)
		assert_validation_fails_for(li, ['item'])
	end
	test "validation fails in absence of user" do
		li = Listitem.new(:title=>'test3')
		li.item = pages(:one)
		assert_validation_fails_for(li, ['user'])
	end
	test "validation passes in absence of title" do
		li = Listitem.new()
		li.item = pages(:one)
		li.user = users(:login)
		assert_valid li
	end
	test "validation passes with empty title" do
		li = Listitem.new(:title=>'')
		li.item = pages(:one)
		li.user = users(:login)
		assert_valid li
	end
	test "validation passes with space in title" do
		li = Listitem.new(:title=>"test 4")
		li.item = pages(:one)
		li.user = users(:login)
		assert_valid li
	end
	test "validation fails with space at beginning of title" do
		li = Listitem.new(:title=>" test5")
		li.item = pages(:one)
		li.user = users(:login)
		assert_validation_fails_for(li, ['title'])
	end
	test "validation fails with space at end of title" do
		li = Listitem.new(:title=>"test6 ")
		li.item = pages(:one)
		li.user = users(:login)
		assert_validation_fails_for(li, ['title'])
	end
	test "validation passes with dash in title" do
		li = Listitem.new(:title=>"test-7")
		li.item = pages(:one)
		li.user = users(:login)
		assert_valid li
	end
	test "validation fails with dash at beginning of title" do
		li = Listitem.new(:title=>"-test8")
		li.item = pages(:one)
		li.user = users(:login)
		assert_validation_fails_for(li, ['title'])
	end
	test "validation fails with dash at end of title" do
		li = Listitem.new(:title=>"test9-")
		li.item = pages(:one)
		li.user = users(:login)
		assert_validation_fails_for(li, ['title'])
	end
	test "validation fails with CR in title" do
		li = Listitem.new(:title=>"\r")
		li.item = pages(:one)
		li.user = users(:login)
		assert_validation_fails_for(li, ['title'])
	end
	test "validation fails for duplicate entry" do
		li = Listitem.new(:title=>listitems(:one).title)
		li.item = listitems(:one).item
		li.user = listitems(:one).user
		assert_validation_fails_for(li, ['title'])
	end
	
	
	# CLASS METHODS
	
	test "default include" do
		assert_nil Listitem.default_include
	end
	
	test "default order" do
		assert_equal 'listitems.created_at', Listitem.default_order
	end
	test "default order recent" do
		assert_equal 'listitems.updated_at DESC, listitems.created_at',
			Listitem.default_order(:recent=>true)
	end
	
	test "search conditions" do
		assert_nil Listitem.search_conditions
	end
	test "search conditions custom" do
		assert_equal ['a AND b',1,2], Listitem.search_conditions({}, ['a','b'], [1,2])
	end
	test "search conditions title" do
		assert_equal ['listitems.title = ?', 'Title'],
			Listitem.search_conditions({:title=>'Title'})
	end
	test "search conditions user" do
		assert_equal ['listitems.user_id = ?', 1],
			Listitem.search_conditions({:u=>1})
	end
	test "search conditions all" do
		assert_equal ['a AND b AND listitems.title = ? AND listitems.user_id = ?',
				1, 2, 'Title', 3],
			Listitem.search_conditions({:title=>'Title', :u=>3}, ['a','b'], [1,2])
	end
	
	test "find lists for user" do
		lists = Listitem.find_lists_for_user(users(:login))
		assert_equal 1, lists.size
		assert_equal 'Test List', lists[0].title
	end
	test "find lists for user with no lists" do
		assert_equal [], Listitem.find_lists_for_user(users(:another))
	end
	test "find lists for user with nil user" do
		assert_raise RuntimeError do
			Listitem.find_lists_for_user(nil)
		end
	end
	
	def self.count_user_list(u, title)
		Listitem.count(:conditions=>
			['listitems.user_id = ? AND listitems.title = ?', u.id, title])
	end
	
	test "count items in user list" do
		assert_equal 2, Listitem.count_user_list(listitems(:one).user, listitems(:one).title)
	end
	test "count items in empty user list" do
		assert_equal 0, Listitem.count_user_list(listitems(:one).user, 'non-existent list')
	end
	test "count items in user list for wrong user" do
		assert_equal 0, Listitem.count_user_list(users(:another), listitems(:one).title)
	end
	test "count items in user list for no user" do
		assert_raise RuntimeError do
			Listitem.count_user_list(nil, listitems(:one).title)
		end
	end
end
