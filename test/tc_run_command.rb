#!/usr/bin/env ruby -wKU

require "test/unit"

require "rrdb"

class TestRunCommand < Test::Unit::TestCase
  def test_run_command_returns_the_output_of_a_shell_command_on_success
    assert_instance_of(String, RRDB.run_command("rrdtool -v"))
  end
  
  def test_run_command_returns_nil_on_failure_or_error
    assert_nil(RRDB.run_command("BROKENrrdtool -v"))
  end
end