#!/usr/bin/env rake

require "rake/testtask"
require "rake/rdoctask"

task :default => [:test]

Rake::TestTask.new do |test|
	test.libs       << "test"
	test.test_files =  %w[test/ts_all.rb]
	test.verbose    =  true
end

Rake::RDocTask.new do |rdoc|
	rdoc.main     = "README"
	rdoc.rdoc_dir = "doc/html"
	rdoc.title    = "RRDB Documentation"
	rdoc.rdoc_files.include( *%w[ README  INSTALL CHANGELOG
	                              AUTHORS COPYING LICENSE
	                              lib/ ] )
end
