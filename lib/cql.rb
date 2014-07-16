require "lib/antlr4-runtime-4.2.2.jar"
require "lib/cql-0.1.jar"
require "hqmf-parser"
require_relative 'cql/utilities.rb'
require_relative 'cql/data_criteria.rb'
require_relative 'cql/precondition.rb'
require_relative 'cql/population.rb'
require_relative 'cql/types.rb'
require_relative 'cql/parser.rb'

java_import org.antlr.v4.runtime.ANTLRInputStream
java_import org.antlr.v4.runtime.CommonTokenStream
java_import org.antlr.v4.runtime.tree.ParseTree
java_import org.antlr.v4.runtime.tree.ParseTreeWalker
CQL_LEXER = org.cqframework.cql.gen.cqlLexer
CQL_PARSER = org.cqframework.cql.gen.cqlParser

