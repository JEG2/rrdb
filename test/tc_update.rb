#!/usr/bin/env ruby -wKU

require "test/unit"

require "rrdb"
require File.join(File.dirname(__FILE__), "rrd_manager")

class TestUpdate < Test::Unit::TestCase
  include RRDManager
  
  def test_fields_returns_an_empty_array_for_a_non_existent_database
    assert_equal(Array.new, @db.fields)
  end
  
  def test_update_claims_new_fields_as_needed
    @db.update(Time.now, :a => 1)
    %w[b c].each do |field|
      assert(!@db.fields.include?(field), "Unused field in database.")
    end
    @db.update(Time.now + 10, :b => 2, :c => 3)
    %w[b c].each do |field|
      assert(@db.fields.include?(field), "Field not claimed in database.")
    end
  end
  
  def test_fields_are_retyped_on_claim
    RRDB.config(:reserve_fields => 2)
    @db.update(Time.now, :a => 1)
    assert_match(/\AGAUGE:/, @db.fields(true)["_reserved0"])
    RRDB.config(:data_sources => {:b => "COUNTER:600:U:U"})
    @db.update(Time.now + 10, :b => 2)
    assert_match(/\ACOUNTER:/, @db.fields(true)["b"])
  end
  
  def test_bad_schema_for_update_raises_tune_error
    RRDB.config(:reserve_fields => 2)
    @db.update(Time.now, :a => 1)
    RRDB.config(:data_sources => {:b => "BAD_FIELD_TYPE"})
    assert_raise(RRDB::TuneError) { @db.update(Time.now + 10, :b => 2) }
  end
  
  def test_running_out_of_fields_to_claim_raises_fields_exhausted_error
    RRDB.config(:reserve_fields => 3)
    test_update_claims_new_fields_as_needed
    assert_raise(RRDB::FieldsExhaustedError) do
      @db.update(Time.now + 20, :d => 0)
    end
  end
  
  def test_unsupported_characters_are_removed_from_names
    @db.update(Time.now, "a'b)" => 4)
    assert(@db.fields.include?("ab"), "Trimmed field name not found.")
  end
  
  def test_common_symbols_are_translated
    @db.update(Time.now, '~ z ! @#$%^&*-+=|<>./?' => 4)
    assert( @db.fields.include?("tzbahdpcnmmveplgddq"),
            "Common symbols were not translated." )
  end
  
  def test_fields_that_differ_only_by_symbol
    @db.update(Time.now, "Swap Used" => 1, "% Swap Used" => 2)
    assert(@db.fields.include?("SwapUsed"), "Non-symbol field was not found.")
    assert(@db.fields.include?("pSwapUsed"), "Symbol field was not found.")
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
      @db.update(Time.now, "`(){}[]'" => 7)
    end
  end
  
  def test_ambiguous_field_names_raise_errors
    assert_raise(RRDB::FieldNameConflictError) do
      @db.update(Time.now, "ab" => 8, "a'b" => 9)
    end
  end
  
  def test_you_can_retrieve_the_field_name_used
    assert_equal( ("a".."z").to_a.join[0..18],
                  RRDB.field_name(("a".."z").to_a.join.gsub(/\b/, "'")) )
  end
  
  def test_illegal_updates_raise_update_error
    test_unsupported_characters_are_removed_from_names  # create a db
    assert_raise(RRDB::UpdateError) do
      @db.update(Time.now - 10, Hash.new)               # time in the past
    end
  end
end
