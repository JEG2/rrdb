#!/usr/bin/env ruby -wKU

require "test/unit"

require "rrdb"
require File.join(File.dirname(__FILE__), "rrd_manager")

class TestUpdate < Test::Unit::TestCase
  include RRDManager
  
  def test_update_claims_new_fields_as_needed
    @db.update(Time.now, :a => 1)
    %w[b c].each do |field|
      assert(!@db.fields.include?(field), "Unused field in database.")
    end
    @db.update(Time.now, :b => 2, :c => 3)
    %w[b c].each do |field|
      assert(@db.fields.include?(field), "Field not claimed in database.")
    end
  end
  
  def test_unsupported_characters_are_removed_from_names
    @db.update(Time.now, "a'b=" => 4)
    assert(@db.fields.include?("ab"), "Trimmed field name not found.")
  end
  
  def test_long_field_names_are_shortened_on_entry
    @db.update(Time.now, ("a".."z").to_a.join => 5)
    assert( @db.fields.include?(("a".."z").to_a.join[0..18]),
            "Shortened field name not found." )
  end
  
  def test_field_names_must_be_at_least_one_supported_character_long
    assert_raise(RRDB::FieldNameConflictError) do
      @db.update(Time.now, String.new => 6)
    end
    assert_raise(RRDB::FieldNameConflictError) do
      @db.update(Time.now, "!@\#$%^&*" => 7)
    end
  end
  
  def test_you_can_retrieve_the_field_name_used
    assert_equal( ("a".."z").to_a.join[0..18],
                  RRDB.field_name(("a".."z").to_a.join.gsub(/\b/, "'")) )
  end
end
