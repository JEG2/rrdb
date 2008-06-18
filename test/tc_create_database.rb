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
  
  def test_step_defaults_to_three_hundred_for_a_non_existent_database
    assert_equal(300, @db.step)
  end
  
  def test_illegal_schema_raise_create_error
    RRDB.config(:round_robin_archives => nil)
    assert_raise(RRDB::CreateError) { @db.update(Time.now, :a => 1) }
  end
  
  def test_field_type_can_be_set_globally_for_all_created_fields
    RRDB.config(:reserve_fields => 0, :data_sources => "GAUGE:1200:U:U")
    @db.update(Time.now, :a => 1, :b => 2, :c => 3)
    @db.fields(true).each_value do |type|
      assert_equal("GAUGE:1200:U:U", type)
    end
  end
  
  def test_field_type_can_be_set_with_hash_lookup
    RRDB.config( :reserve_fields => 0,
                 :data_sources   => { :a => "GAUGE:100:U:U",
                                      :b => "GAUGE:200:U:U",
                                      :c => "GAUGE:300:U:U" } )
    @db.update(Time.now, :a => 1, :b => 2, :c => 3)
    types = @db.fields(true)
    RRDB.config[:data_sources].each do |field, type|
      assert_equal(type, types[field.to_s])
    end
  end
  
  def test_field_type_can_be_set_with_lambda
    RRDB.config( :reserve_fields => 0,
                 :data_sources   => lambda { |f| f == :a ? "GAUGE:100:U:U" :
                                                           "GAUGE:200:U:U" } )
    @db.update(Time.now, :a => 1, :b => 2, :c => 3)
    @db.fields(true).each do |field, type|
      assert_equal(RRDB.config[:data_sources][field.to_sym], type)
    end
  end
end
