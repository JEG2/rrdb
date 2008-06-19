Gem::Specification.new do |s|
  s.name             = "rrdb"
  s.summary          = "A simple wrapper for RRDtool."
  s.description      = "RRDB is a wrapper for RRDtool that provides methods " +
                       "for creating databases, updating them with new "      +
                       "entries, and fetching consolidation functions from "  +
                       "them."
  s.homepage         = "http://github.com/JEG2/rrdb"
  s.date             = "2008-06-19"
  s.version          = File.read(
                         File.join(File.dirname(__FILE__), *%w[lib rrdb.rb])
                       )[/^\s*VERSION\s*=\s*(['"])(\d\.\d\.\d)\1/, 2]
  s.platform         = Gem::Platform::RUBY
  s.authors          = ["James Edward Gray II"]
  s.email            = "james@graysoftinc.com"
  s.files            = Dir["{lib,test}/**/*.rb"] + 
                       %w[Rakefile setup.rb]
	s.require_path     = "lib"
  s.test_suite_file  = "test/ts_all.rb"
  s.has_rdoc         = true
  s.rdoc_options     = %w[--title RRDB\ Documentation --main README]
  s.extra_rdoc_files = %w[ README  INSTALL CHANGELOG AUTHORS COPYING LICENSE 
                           lib/ ]
end
