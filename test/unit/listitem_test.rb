require 'test_helper'

class ListitemTest < ActiveSupport::TestCase
	fixtures :lists, :listitems, :pages, :users, :events
	
	# Replace this with your real tests.
	test "associations" do
		assert check_associations
	end
	
	
	# VALIDATIONS
	
	test "validation with all values set" do
		li = lists(:one).listitems.new()
		li.item = pages(:three)
		assert_valid li
	end
	test "validation fails in absence of item" do
		li = lists(:one).listitems.new()
		assert_validation_fails_for(li, ['item'])
	end
	test "validation fails for duplicate entry" do
		li = listitems(:one).list.listitems.new()
		li.item = listitems(:one).item
		assert_validation_fails_for(li, ['item_id'])
	end
	
	
	# CLASS METHODS
	
	test "default include" do
		assert_nil Listitem.default_include
	end
	
	test "default order" do
		assert_equal 'listitems.position', Listitem.default_order
	end
	test "default order recent" do
		assert_equal 'listitems.updated_at DESC, listitems.position',
			Listitem.default_order(:recent=>true)
	end
	
	test "search conditions" do
		assert_nil Listitem.search_conditions
	end
	test "search conditions custom" do
		assert_equal ['a AND b',1,2], Listitem.search_conditions({}, ['a','b'], [1,2])
	end
	test "search conditions all" do
		assert_equal ['a AND b',
				1, 2],
			Listitem.search_conditions({}, ['a','b'], [1,2])
	end
	
	
	# INSTANCE METHODS
	
	test "before save sets position" do
		li = lists(:one).listitems.new()
		li.item = events(:searchable)
		li.save!
		assert_equal 3, li.position
		li.destroy
	end
	
	test "autoset_position" do
		li = lists(:one).listitems.new()
		li.autoset_position
		assert_equal 3, li.position
	end
	
	test "css class" do
		assert_equal 'event', listitems(:one).css_class
	end
	test "css class with prefix" do
		assert_equal 'test-event', listitems(:one).css_class('test-')
	end
end
