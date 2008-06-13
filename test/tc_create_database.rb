#!/usr/bin/env ruby -wKU

require "test/unit"

require "rrdb"
require File.join(File.dirname(__FILE__), "rrd_manager")

class TestCreateDatabase < Test::Unit::TestCase
  include RRDManager
  
  def test_database_is_not_created_with_instance
    assert(!File.exist?(@db.path), "Database existed before update.")
  end

  def test_database_is_created_at_first_update
    @db.update(Time.now, :some_field => 10)
    assert(File.exist?(@db.path), "Database wasn't created at update time.")
  end
  
  def test_fields_in_initial_update_are_in_the_created_database
    @db.update(Time.now, :a => 1, :b => 2, :c => 3)
    %w[a b c].each do |field|
      assert(@db.fields.include?(field), "Field not in created database.")
    end
  end
  
  def test_extra_fields_are_reserved_in_the_created_database_by_config
    RRDB.config(:reserve_fields => 3)
    @db.update(Time.now, :a => 1)
    2.times do |i|
      assert( @db.fields.include?("_reserved#{i}"),
              "Reserved field not in created database." )
    end
  end
  
  def test_step_can_be_customized_for_creation
    RRDB.config(:database_step => 1_000)
    @db.update(Time.now, :a => 1)
    assert_equal(1_000, @db.step)
  end
end
