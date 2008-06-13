#!/usr/bin/env ruby -wKU

require "test/unit"

require "rrdb"
require File.join(File.dirname(__FILE__), "rrd_manager")

class TestFetch < Test::Unit::TestCase
  include RRDManager
  
  def test_example_data_from_tutorial
    RRDB.config( :reserve_fields       => 0,
                 :database_start       => Time.at(920804400),
                 :data_sources         => {:speed => "COUNTER:600:U:U"},
                 :round_robin_archives => %w[ AVERAGE:0.5:1:24
                                              AVERAGE:0.5:6:10 ] )
    
    %w[ 920804700:12345 920805000:12357 920805300:12363
        920805600:12363 920805900:12363 920806200:12373
        920806500:12383 920806800:12393 920807100:12399
        920807400:12405 920807700:12411 920808000:12415
        920808300:12420 920808600:12422 920808900:12423 ].each do |data_point|
      time, value = data_point.split(":")
      @db.update(Time.at(time.to_i), :speed => value.to_i)
    end
    
    results = @db.fetch( :AVERAGE, :start => Time.at(920804400),
                                   :end   => Time.at(920809200) )
    %w[ 920804700:0
        920805000:4.0000000000e-02
        920805300:2.0000000000e-02
        920805600:0.0000000000e+00
        920805900:0.0000000000e+00
        920806200:3.3333333333e-02
        920806500:3.3333333333e-02
        920806800:3.3333333333e-02
        920807100:2.0000000000e-02
        920807400:2.0000000000e-02
        920807700:2.0000000000e-02
        920808000:1.3333333333e-02
        920808300:1.6666666667e-02
        920808600:6.6666666667e-03
        920808900:3.3333333333e-03
        920809200:0 ].each do |expected|
      time, value = expected.split(":")
      assert_in_delta( Float(value), results[Time.at(time.to_i)]["speed"],
                       2 ** -20 )
    end
  end
end
