Gem::Specification.new do |s|
  s.name             = "rrdb"
  s.summary          = "A simple wrapper for RRDtool."
  s.description      = "RRDB is a wrapper for RRDtool that provides methods " +
                       "for creating databases, updating them with new "      +
                       "entries, and fetching consolidation functions from "  +
                       "them."
  s.homepage         = "http://github.com/JEG2/rrdb"
  s.date             = "2008-06-19"
  s.version          = "0.0.2"
  s.platform         = Gem::Platform::RUBY
  s.authors          = ["James Edward Gray II"]
  s.email            = "james@graysoftinc.com"
  s.files            = %w[lib/rrdb.rb test/rrd_manager.rb test/tc_config.rb test/tc_create_database.rb test/tc_fetch.rb test/tc_run_command.rb test/tc_update.rb test/tc_version.rb test/ts_all.rb] + %w[Rakefile setup.rb]
	s.require_path     = "lib"
  s.test_suite_file  = "test/ts_all.rb"
  s.has_rdoc         = true
  s.rdoc_options     = %w[--title RRDB\ Documentation --main README]
  s.extra_rdoc_files = %w[ README  INSTALL CHANGELOG AUTHORS COPYING LICENSE 
                           lib/ ]
end
