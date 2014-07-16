require 'sinatra'
require 'hqmf-parser'
#require 'java'
require_relative '../cql'

post '/' do
  content_type :json 
  
  cql = request.body.read.to_s
  
  # TODO: Flip the comments for the next 3 lines.  Want to use the Visitor to create model
  # v = Visitor.new
  # model = v.parse(cql)
  model = CQL::Parser.new.parseData(cql)
  model.to_json().to_json
end
