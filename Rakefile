require 'rake'
require 'rake/testtask'
require_relative 'lib/cql.rb'
require_relative 'lib/cdw_exporter/benchmarking/benchmarking.rb'

Rake::TestTask.new(:test_unit) do |t|
  t.libs << "test"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

task :test => [:test_unit] do
  system("open coverage/index.html")
end
