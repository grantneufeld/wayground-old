
desc "Shortcut for functional tests"
task :f => "test:functionals"

desc "Shortcut for controller tests"
task :c => "test:controllers"

desc "Shortcut for view tests"
task :v => "test:views"

desc "Shortcut for unit tests"
task :u => "test:units"

desc "Shortcut for integration tests"
task :i => "test:integration"

desc "Run all types of tests, but stop on failure"
task :t => ["test:units", "test:functionals", "test:integration", "test:controllers", "test:views"]
