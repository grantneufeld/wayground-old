class ViewTestGenerator < Rails::Generator::NamedBase

  def manifest
    record do |m|
      m.directory 'test/views'
      m.template 'view_test.rb', "test/views/#{file_name}_view_test.rb"
    end
  end

  def banner
    "Usage: script/generate view_test Articles index new edit"
  end

end
