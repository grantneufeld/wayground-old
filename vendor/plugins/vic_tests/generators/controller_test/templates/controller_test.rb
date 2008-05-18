require File.dirname(__FILE__) + '/../test_helper'

# We are testing <%= class_name %>Controller's actions
class <%= class_name %>ControllerTest < Test::Rails::ControllerTestCase

  # fixtures :<%= table_name %>

  <% actions.each do |action| -%>
  
  # Testing the <%= action %> method
  def test_<%= action %>
    get :<%= action %>

    assert_response :success

    # assert_assigned :<%= table_name %>, 'value'
  end
  <% end -%>

end
