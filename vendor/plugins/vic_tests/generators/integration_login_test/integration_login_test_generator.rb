class IntegrationLoginTestGenerator < Rails::Generator::NamedBase

  def manifest
    record do |m|
      m.directory 'test/integration'
      m.template 'integration_test.rb', "test/integration/#{file_name}_test.rb"
    end
  end

  def banner
    "Usage: script/generate integration_login_test BlogStories"
  end


end
