require_relative '../test_helper'
require 'hquery-patient-api'

class ParserTest < Test::Unit::TestCase

  
  def test_parsing
    v = Visitor.new
    v.parse("")
    #parse file
    #assert valueset
    #assert sdc
    #assert dc
    #assert preconditions
    #assert populations
    #assert to_modle

  end

  def assert_valuesets(expected, found)

  end

  def assert_source_data_criteria(expected, found)

  end

  def assert_data_criteria(expected, found)

  end

  def assert_preconditions(expected, found)

  end

end