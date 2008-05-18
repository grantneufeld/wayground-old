require File.dirname(__FILE__) + '/../test_helper'

# We are testing <%= class_name %>Controller's views
class <%= class_name %>ViewTest < Test::Rails::ViewTestCase

  # fixtures :<%= table_name %>

  <% actions.each do |action| -%>
  ##
  # Tests the view for the <%= action %> action of <%= class_name %>Controller
  def test_<%= action %>
    # Instance variables necessary for action
    assigns[:<%= table_name %>] = []

    render :action => "<%= action %>"

    # assert_select ...
    # assert_links_to ...
  end
  <% end -%>

end
