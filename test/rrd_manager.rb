#!/usr/bin/env ruby -wKU

module RRDManager
  def setup
    save_config
    modify_config_for_tests
    create_a_new_database
  end
  
  def teardown
    cleanup_rrd_files
    restore_config
  end
  
  def save_config
    @saved_config = RRDB.config.dup
  end
  
  def modify_config_for_tests
    RRDB.config( :database_directory   => File.dirname(__FILE__),
                 :round_robin_archives => "AVERAGE:0.5:1:24" )
  end
  
  def restore_config
    RRDB.config.replace(@saved_config)
  end
  
  def create_a_new_database
    @db = RRDB.new(rand(10_000))
  end
  
  def cleanup_rrd_files
    Dir.glob("#{RRDB.config[:database_directory]}/*.rrd") do |rrd|
      File.unlink(rrd)
    end
  end
end
