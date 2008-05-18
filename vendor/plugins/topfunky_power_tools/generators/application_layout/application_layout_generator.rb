class ApplicationLayoutGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      %w(application.css application.rhtml).each do |filename|
        m.file "application.rhtml", File.join("app", "views", "layouts", "application.rhtml")
        m.file "application.css", File.join("public", "stylesheets", "application.css")
      end
    end
  end
  
end
