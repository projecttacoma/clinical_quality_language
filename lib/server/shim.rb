require 'sinatra'
require 'hqmf-parser'
#require 'java'
#java_import 'CQL'

post '/' do
  content_type :json 
  
  cql = request.body.read.to_s
  
  # TODO: Flip the comments for the next 3 lines.  Want to use the Visitor to create model
  # v = Visitor.new
  # model = v.parse(cql)
  model = HQMF::Parser::V1Parser.new.parse(File.open("./lib/server/test.xml").read)
  
  model.to_json().deep_stringify_keys.to_json
end
