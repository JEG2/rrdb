#!/usr/bin/env rake

require "rake/testtask"

dir     = File.dirname(__FILE__)
lib     = File.join(dir, "lib", "rrdb.rb")
version = File.read(lib)[/^\s*VERSION\s*=\s*(['"])(\d\.\d\.\d)\1/, 2]

task :default => [:test]

Rake::TestTask.new do |test|
	test.libs       << "test"
	test.test_files =  %w[test/ts_all.rb]
	test.verbose    =  true
end
