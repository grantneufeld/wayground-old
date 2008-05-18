
# Useful test helpers.
#
# Many have been looted from stellar test code 
# seen in applications by technoweenie[http://techno-weenie.net]
# and zenspider[http://zenspider.com].
module Topfunky::TestHelper

  ##
  # A simple method for setting the Accept header in a test.
  #
  # Useful for REST controllers that use ++respond_to++ to serve different types of content.
  #
  # Options for ++type_symbol++ are :xml, :js, or :html.
  #
  #  def test_index_should_serve_js
  #    wants :js
  #    get :index
  #    assert_match 'alert', @response.body
  #  end
  #
  def wants(type_symbol)
    @request.accept = case type_symbol
                      when :js
                        'text/javascript'
                      when :xml
                        'text/xml'
                      when :html
                        'text/html'
                      end
  end

  # The opposite of an assert.
  #
  #  deny world.flat?, "A round world was expected, but it was found to be flat."
  def deny(condition, msg = nil)
    assert ! condition, msg
  end

  # Calls creation_method with nil values for field_names and asserts that
  # the resulting object was not saved and that errors were added for that field.
  #
  #  assert_required_fields :create_article, :subject, :body, :author
  def assert_required_fields(creation_method, *field_names)
    field_names.each do |field|
      record = send(creation_method, field => nil)
      assert_equal false, record.valid?
      assert_not_nil record.errors.on(field)
    end
  end

  # See assert_required_fields
  def assert_numeric_fields(creation_method, *field_names)
    field_names.each do |field|
      record = send(creation_method, field => "A")
      assert_equal false, record.valid?
      assert_not_nil record.errors.on(field)
    end
  end

  def assert_invalid_value_for_field(obj, value, field)
    obj.send("#{field}=", value)
    deny obj.valid?
    assert obj.errors.invalid?(field)
  end
  
  def assert_valid_value_for_field(obj, value, field)
    obj.send("#{field}=", value)
    obj.valid? # Calling this activates validations and populates relevant errors
    deny obj.errors.invalid?(field)
  end


 def assert_invalid(model, attribute, *values)
    if values.empty?
      assert ! model.valid?, "Object is valid with value: #{model.send(attribute)}"
      assert ! model.save, "Object saved."
      assert model.errors.invalid?(attribute.to_s), "#{attribute} has no attached error"
    else
      values.flatten.each do |value|
        obj = model.dup
        obj.send("#{attribute}=", value)
        assert_invalid obj, attribute
      end
    end
  end

  def assert_valid(model, attribute=nil, *values)
    if values.empty?
      unless attribute.nil?
        assert model.valid?, "Object is not valid with value: #{model.send(attribute)}"
      else
        assert model.valid?, model.errors.full_messages
      end
      assert model.errors.empty?, model.errors.full_messages
    else
      m = model.dup # the recursion was confusing mysql
      values.flatten.each do |value|
        obj = m.dup
        obj.send("#{attribute}=", value)
        assert_valid(obj, attribute)
      end
    end
  end

  # http://project.ioni.st/post/217#post-217
  # and http://blog.caboo.se/articles/2006/06/13/a-better-assert_difference
  #
  # Is the result different? Can be used for increment or decrement.
  #
  # A nil arg for +difference+ will just check to make sure that the difference was not 0.
  # This can be useful when checking against a large number of objects that might change
  # in different ways (cascading deletes, etc.).
  #
  #  def test_new_publication
  #    assert_difference(Publication, :count) do
  #      post :create, :publication => {...}
  #      # ...
  #    end
  #  end
  #
  # You can also send an array of objects to check against.
  #
  #  def test_destroy
  #    assert_difference [Article, Section, Column, Vote], :count, nil do
  #      @section.destroy
  #    end
  #  end
  #  
  # or with an explicit initial value
  #  
  #  def test_count_created_since
  #    assert_difference(Publication, [:count_created_since, Time.now.midnight.utc], 1)
  #      post :create, :publication => {...}
  #      # ...
  #    end
  #  end
  # 
  #
  def assert_difference(objects, method_and_args = nil, difference = 1)
    objects = [objects].flatten

    method_and_args = [method_and_args] unless method_and_args.is_a? Array
    method = method_and_args.shift
    args = method_and_args

    initial_values = objects.inject([]) { |sum,obj| sum << obj.send(method, *args) }
    yield
    if difference.nil?
      objects.each_with_index { |obj,i|
        assert_not_equal initial_values[i], obj.send(method, *args), "#{obj}##{method}"
      }
    else
      objects.each_with_index { |obj,i|
        assert_equal initial_values[i] + difference, obj.send(method, *args), "#{obj}##{method}"
      }
    end
  end

  def assert_no_difference(objects, method, &block)
    assert_difference objects, method, 0, &block
  end

  def assert_error_on(field, model)
  	assert !model.errors[field.to_sym].nil?, "No validation error on the #{field.to_s} field."
  end
  
  def assert_no_error_on(field, model)
  	assert model.errors[field.to_sym].nil?, "Validation error on #{field.to_s}."
  end

  # Compares a regular expression to the body text returned by a functional test.
  #
  #  assert_match_body /<doctype/
  def assert_match_body(regex)
    assert_match regex, @response.body
  end
  
  def assert_no_match_body(regex)
    assert_no_match regex, @response.body
  end
  
  def assert_match_headers(header, regex)
    assert_match regex, @response.headers[header]
  end
  
end
