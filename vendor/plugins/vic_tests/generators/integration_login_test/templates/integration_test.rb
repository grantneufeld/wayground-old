require File.dirname(__FILE__) + '/../test_helper'

##
# Assumes that you have the following methods in your app or routes:
#
#   login_url, sessions_url, home_url
#
# Assumes that you have a 'users' table and fixture.

class <%= class_name %>Test < ActionController::IntegrationTest

  # fixtures :users

  def test_with_login
    quentin = new_session_as('quentin', 'quentins_password')
    quentin.go_to_seattle
    quentin.visit_seattle_rb
  end

  def test_anonymous_session
    new_session do |guest|
      guest.go_to_index
    end
  end
  
  # Write more tests here that call methods in <%= class_name %>Tasks
  
private

  module <%= class_name %>Tasks

    attr_reader :user

    ## If you put all your test assertions in a module,
    ## include it here. Be sure to require it in test_helper.rb
    # include <%= class_name %>Assertions

    def goes_to_login
      get login_url
      assert_response :success
    end

    def logs_in_as(login, password)
      @user = users(login.to_sym)
      post sessions_url, "login" => login, "password" => password

      assert_redirected_to home_url
    end
    
    # Write more stories here...
    
  end
  
  # Create a session for a user. Block-based.
  #
  #  new_session do |bob|
  #    bob.go_to_login
  #    ...
  #  end
  #
  def new_session
    open_session do |sess|
      sess.extend(<%= class_name %>Tasks)
      yield sess if block_given?
    end
  end

  # Create a new session and return a user object.
  #
  #   bob = new_session_as('bob', 'atest')
  #   bob.goes_to_newspaper
  #   bob.publishes_article
  #   bob.wins_pulitzer
  #
  def new_session_as(login, password)
    new_session do |sess|
      sess.goes_to_login
      sess.logs_in_as(login, password)
      yield sess if block_given?
    end
  end
  
end
