require 'rake'
require 'rake/testtask'
require_relative 'lib/cql.rb'

Rake::TestTask.new(:test_unit) do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task :server do
  ruby "lib/server/shim.rb"
end

task :test => [:test_unit] do
  system("open coverage/index.html")
end
