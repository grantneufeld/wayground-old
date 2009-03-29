require 'test_helper'

class ListTest < ActiveSupport::TestCase
	fixtures :lists, :listitems, :pages, :users, :events
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	# ••• INCOMPLETE
	
	test "validation passes in absence of title" do
		list = List.new()
		list.user = users(:login)
		assert_valid list
	end
	test "validation passes with empty title" do
		list = List.new(:title=>'')
		list.user = users(:login)
		assert_valid list
	end
	test "validation passes with space in title" do
		list = List.new(:title=>"test 4")
		list.user = users(:login)
		assert_valid list
	end
	test "validation fails with space at beginning of title" do
		list = List.new(:title=>" test5")
		list.user = users(:login)
		assert_validation_fails_for(list, ['title'])
	end
	test "validation fails with space at end of title" do
		list = List.new(:title=>"test6 ")
		list.user = users(:login)
		assert_validation_fails_for(list, ['title'])
	end
	test "validation fails with dash in title" do
		list = List.new(:title=>"test-7")
		list.user = users(:login)
		assert_validation_fails_for(list, ['title'])
	end
	test "validation fails with CR in title" do
		list = List.new(:title=>"\r")
		list.user = users(:login)
		assert_validation_fails_for(list, ['title'])
	end
	
	
	# CLASS METHODS
	
	test "default include" do
		assert_nil List.default_include
	end
	
	test "default order" do
		assert_equal 'lists.title', List.default_order
	end
	test "default order recent" do
		assert_equal 'lists.updated_at DESC, lists.title',
			List.default_order(:recent=>true)
	end
	
	test "search conditions" do
		assert_equal ['lists.is_public = 1'], List.search_conditions
	end
	test "search conditions with title" do
		assert_equal ['lists.title = ? AND lists.is_public = 1', 'Test Title'],
			List.search_conditions(:title=>'Test Title')
	end
	test "search conditions with u" do
		assert_equal ['(lists.user_id = ? OR lists.is_public = 1)', users(:login)],
			List.search_conditions(:u=>users(:login))
	end       
	test "search conditions with user" do
		assert_equal ['lists.user_id = ?', users(:login)],
			List.search_conditions(:user=>users(:login))
	end       
	test "search conditions custom" do
		assert_equal ['a AND b AND lists.is_public = 1',1,2],
			List.search_conditions({}, ['a','b'], [1,2])
	end
	test "search conditions all" do
		assert_equal [
			'a AND b AND lists.title = ? AND (lists.user_id = ? OR lists.is_public = 1)',
			1, 2, 'Test Title', users(:login)],
			List.search_conditions({:title=>'Test Title', :u=>users(:login)}, ['a','b'], [1,2])
	end
	
	test "find list titles for user" do
		assert_equal [lists(:one).title, lists(:two).title],
			List.find_list_titles_for_user(users(:login))
	end
	test "find lists for user with no lists" do
		assert_equal [], List.find_list_titles_for_user(users(:another))
	end
	test "find lists for user with nil user" do
		assert_raise RuntimeError do
			List.find_list_titles_for_user(nil)
		end
	end
	
	test "find default list for user" do
		assert_equal lists(:regular_default), List.find_default_list_for_user(users(:regular))
	end
	
	
	# INSTANCE METHODS
	
	test "subpath" do
		assert_equal 'List-One', lists(:one).subpath
	end
	
	test "css class" do
		assert_equal 'list', lists(:one).css_class
	end
	test "css class with prefix" do
		assert_equal 'test-list', lists(:one).css_class('test-')
	end
	
end
