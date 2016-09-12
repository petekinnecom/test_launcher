require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.test_files = Dir.glob("test/test_launcher/**/*_test.rb").reject {|f| f.match("fixtures")}
end

task :default => [:test]
