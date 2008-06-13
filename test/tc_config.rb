#!/usr/bin/env ruby -wKU

require "test/unit"

require "rrdb"
require File.join(File.dirname(__FILE__), "rrd_manager")

class TestConfig < Test::Unit::TestCase
  include RRDManager
  
  def test_config_is_a_hash_with_defaults
    assert_instance_of(Hash, RRDB.config)
    assert_not_nil(RRDB.config[:reserve_fields])
  end
  
  def test_alternative_interface_to_access_config_values
    assert_equal(RRDB.config[:reserve_fields], RRDB.config(:reserve_fields))
  end
  
  def test_adding_new_values_to_the_config
    assert_nil(RRDB.config[:config_value_from_tests])
    RRDB.config(:config_value_from_tests => true)
    assert_not_nil(RRDB.config[:config_value_from_tests])
  end
  
  def test_updating_the_config
    old_value = RRDB.config[:reserve_fields]
    RRDB.config(:reserve_fields => old_value.to_i + 1)
    assert_not_equal(old_value, RRDB.config[:reserve_fields])
  end
  
  def test_config_tries_to_locate_rrdtool
    assert_match(/\brrdtool\z/, RRDB.config[:rrdtool_path])
  end
end
