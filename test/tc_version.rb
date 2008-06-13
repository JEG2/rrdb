#!/usr/bin/env ruby -wKU

require "test/unit"

require "rrdb"

class TestVersion < Test::Unit::TestCase
  def test_version_includes_major_minor_and_tiny
    assert_match(/\A\d\.\d\.\d\z/, RRDB::VERSION)
  end
end
