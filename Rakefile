#!/usr/bin/env rake

require "rake/testtask"
require "rake/rdoctask"

require "fileutils"

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

desc "Updates the .gemspec file so GitHub will rebuild it"
task :update_gem do
  version = File.read(
              File.join(File.dirname(__FILE__), *%w[lib rrdb.rb])
            )[/^\s*VERSION\s*=\s*(['"])(\d\.\d\.\d)\1/, 2]
  open("rrdb.gemspec") do |old_spec|
    open("new_rrdb.gemspec", "w") do |new_spec|
      old_spec.each do |line|
        if line =~ /\A(\s*s\.version\s*=\s*)(["'])\d\.\d\.\d\2\s*\z/
          new_spec.puts %Q{#{$1}"#{version}"}
        elsif line =~ /\A(\s*s\.files\s*=\s*)/
          new_spec.puts %Q{#{$1}%w[#{Dir["{lib,test}/**/*.rb"].join(" ")} } +
                        "Rakefile setup.rb]"
        else
          new_spec.puts line
        end
      end
    end
  end
  FileUtils.mv("new_rrdb.gemspec", "rrdb.gemspec")
end
