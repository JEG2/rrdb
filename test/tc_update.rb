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
end
