class ControllerTestGenerator < Rails::Generator::NamedBase

  def manifest
    record do |m|
      m.directory 'test/controllers'
      m.template 'controller_test.rb', "test/controllers/#{file_name}_controller_test.rb"
    end
  end

  def banner
    "Usage: script/generate controller_test Articles index new edit"
  end

end
