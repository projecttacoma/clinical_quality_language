require_relative '../test_helper'

class ParserTest < Minitest::Test

  
  def test_parsing
    p = CQL::Parser.new
    doc = p.parse("test/fixtures/cql/ChlamydiaScreening_QDM.cql")
    assert doc
    File.open("tmp.json", "w") do |f|
      f.puts doc.to_json.to_json
    end

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