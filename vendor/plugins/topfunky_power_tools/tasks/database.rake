namespace :topfunky do
  namespace :db do
    namespace :schema do
      desc "Report the current version of the database schema. Send RAILS_ENV to check a specific database."
      task :version => :environment do
        r = ActiveRecord::Base.connection.execute "SELECT version FROM schema_info LIMIT 1"
        puts "SCHEMA VERSION: #{r.fetch_hash['version']}"
      end

      desc "Report the current version of the database schema. Send RAILS_ENV to check a specific database."
      task :force_version => :environment do
        raise "You must provide VERSION=#" unless ENV['VERSION'].to_i > 0
        r = ActiveRecord::Base.connection.execute "UPDATE schema_info SET version = #{ENV['VERSION']}"
        Rake::Task["topfunky:db:schema:version"].invoke
      end

    end

    namespace :sessions do
      desc "Clear database-stored sessions older than two weeks"
      task :clear => :environment do
        CGI::Session::ActiveRecordStore::Session.delete_all ["updated_at < ?", 2.weeks.ago ] 
      end

      desc "Count database sessions"
      task :count => :environment do
        puts "Currently storing #{CGI::Session::ActiveRecordStore::Session.count} sessions"
      end      
    end
  end
end

# !!EXPERIMENTAL!!
task :setup_migrate_dry do
  # Override execute
  ActiveRecord::Base.connection.class.class_eval <<-CODE
    alias_method :real_execute, :execute
    def execute(sql, name=nil)
      case sql
      when /(SELECT|CREATE|INSERT).* schema_info/
        real_execute sql, name
      when /SELECT/
        real_execute sql, name
      else
        puts "   DRY RUN: " + sql
      end
    end
  CODE
  # Don't set the schema version
  class ActiveRecord::Migrator
    def set_schema_version(version)
      # do nothing
    end
  end
  # Don't dump the schema
  class ActiveRecord::SchemaDumper
    def self.dump(connection=ActiveRecord::Base.connection, stream=STDOUT)
      # do nothing
    end
  end
  
  puts "** DRY RUN (Non-destructive) **"
end
desc "Run migrations without actually changing the database."
task :migrate_dry => [:environment, :setup_migrate_dry, :migrate]

