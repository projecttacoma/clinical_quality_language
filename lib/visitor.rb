require 'hqmf-parser'
class Visitor <  org.cqframework.cql.gen.cqlBaseVisitor

  include CQL::Utilities
  POPULATION_IDENTIFIERS = ["IPP"]
  FUNCTION_HANDLERS = {"AgeAt" => :t,
                       "ValueSet" => :vs}
  attr_accessor :doc
  attr_accessor :valuesets
  attr_accessor :data_criteria 
  attr_accessor :source_data_criteria 
  attr_accessor :preconditions 
  attr_accessor :populations 
  attr_accessor :parameters 
  attr_accessor :dc_ids


  def initialize
    @bind = false
    @counter = 1
    @valuesets = {}
    @data_criteria = {}
    @source_data_criteria = {}
    @preconditions = {}
    @populations = {}
    @parameters = {}
    @dc_ids = {}
    @current_parsing_context = {}
  end

  def next_id
    @counter += 1
    @counter
  end
  
  def generate_grouper_id(type)
    "GROUP_#{type}_#{next_id}"
  end

  def to_hqmf_modle

  end


  def parse(file)
    data =  File.read(file)
    input =  ANTLRInputStream.new(data);
    lexer =  CQL_LEXER.new(input)
    tokens = CommonTokenStream.new(lexer)
    parser = CQL_PARSER.new(tokens)
    parser.setBuildParseTree(true)
    tree = parser.logic()
    visit(tree)
  end
  
  def visitInclude(ctx)
    parse(ctx.IDENTIFIER.text)
  end

  def visitLogic(logic)
    puts "logic"
    valuesets = logic.valuesetDefinition.collect do |vs|
      vs.accept(self)
    end
    statements = logic.statement.collect do |vs|
      vs.accept(self)
    end
  end

  # | expression ('or' | 'xor') expression                               # orExpression
  def visitOrExpression(ctx)
     handlePrecondition(ctx,"anyTrue")
  end

  # | expression 'and' expression                                        # andExpression
  def visitAndExpression(ctx)
    handlePrecondition(ctx, "allTrue")
  end

  def handleGrouper(ctx,operator)
     # binding.pry if @bind
     grouper = ctx.expression(0).accept(self)
     if !grouper || grouper.kind_of?(String)|| !grouper.derived? || grouper.derivation_operator != operator # if not an or grouper create one
       exp = grouper
       grouper = CQL::DataCriteria.new({derived: true, derivation_operator: operator, children_criteria:[], id: generate_grouper_id(operator)})
       if exp.kind_of? CQL::DataCriteria
         grouper.children_criteria << exp.id
       else
         grouper.children_criteria << exp
       end
       @data_criteria[grouper.id] = grouper
     end
     exp2 = ctx.expression(1).accept(self)
     if exp2.kind_of? CQL::DataCriteria
        grouper.children_criteria << exp2.id
     else 
        grouper.children_criteria << exp2
     end
     grouper
  end


def handlePrecondition(ctx,operator)
     # binding.pry if @bind
     precondition = ctx.expression(0).accept(self)
     if !precondition || precondition.kind_of?(String) || precondition.kind_of?(CQL::DataCriteria)
        reference = precondition.kind_of?(CQL::DataCriteria) ? precondition.id : precondition # dc id or its a reference to a dc
        child = @current_parsing_context[reference]
        if !child || !child.kind_of?(CQL::PreCondition)
          child = CQL::PreCondition.new(next_id, nil,nil,reference)
        end
        precondition = CQL::PreCondition.new(next_id, operator,[child],nil)
     end
     exp2 = ctx.expression(1).accept(self)
     if exp2.kind_of?(CQL::DataCriteria) || exp2.kind_of?(String)
        reference = exp2.kind_of?(CQL::DataCriteria) ? exp2.id : exp2 
        child = @current_parsing_context[reference]
        if !child || !child.kind_of?(CQL::PreCondition)
          child = CQL::PreCondition.new(next_id, nil,nil,reference)
        end
        precondition.preconditions << child
     else 
        precondition.preconditions << exp2
     end
     precondition
  end

# | ('not' | 'exists') expression                                      # existenceExpression
  def visitExistenceExpression(ctx)
    ex = "" # get existence 
    data_criteria = ctx.expression.accept(self)
    if ex == "not"
      data_criteria.negation = true
    end
    data_criteria || " NULL "
  end

 # | expression intervalOperatorPhrase expression                       # timingExpression
  def visitTimingExpression(ctx)

  end

  # return the temporal code and range for the phrase
  def visitIntervalOperatorPhrase(ctx)

  end

  def visitQuerySource(ctx)
    ex  = ctx.retrieve || ctx.expression
    identifier = ctx.IDENTIFIER
    sdc = ex.accept(self) if ex
    sdc = @current_parsing_context[identifier.text] if identifier
    sdc.dup
  end
  #parse the retrieve into a source_data_criteria and set the context variable to be used
  #for the data_criteria in the expression
  def visitAliasedQuerySource(ctx)
    sdc = ctx.query_source.accept(self)
    _alias = ctx.alias.text
    return sdc.dup,_alias
  end

# | aliasedQuerySource queryInclusionClause* ('where' expression)? ('return' expression)? ('sort' 'by' sortByItem (',' sortByItem)*)?
  #                                                                      # queryExpression
  def visitQueryExpression(ctx)
    _context = @current_parsing_context
    @current_parsing_context = _context.dup
    dc,_alias = ctx.aliased_query_source.accept(self)
    @current_parsing_context[_alias]=dc
    @current_parsing_context = _context
    @data_criteria[dc.id] = dc
    dc
  end

  

  def visitValuesetDefinition(vs)
    # get the identifier and the oid for the vs and add it to the cache
     name = vs.STRING().text()
     oid = vs.expression().text().gsub("ValueSet(","").gsub(")","")
     @valuesets[name] = oid
  end

  def visitLetStatement(let)
    # binding.pry
      _id = let.IDENTIFIER().text()
      if HQMF::PopulationCriteria::ALL_POPULATION_CODES.index(_id)
        val = handle_population(_id,let)
      else
        val = handle_precondition(_id,let)  
        @current_parsing_context[_id]=val
      end
  end

  def visitRetrieve(retrieve) 
    text = retrieve.text()
    unless @source_data_criteria[text]
      text.gsub!("[","").gsub("]","")
      topic = retrieve.topic().text()
      modality = retrieve.modality().text() if retrieve.modality()
      valueset = retrieve.valueset().text()
      oid = @valuesets[valueset] || ""
      type = "#{topic}, #{modality}"
      _id = format_id(text)
      settings = {title: type, description: type, code_list_id: oid ,source_data_criteria: _id, id: _id, negation:false, display_name: type}
      settings.merge!(parse_definition_and_status(type))                                      
      @source_data_criteria[retrieve.text()] = CQL::DataCriteria.new(settings)
    end
    @source_data_criteria[retrieve.text()]
  end

  
  # | retrieve                                                           # retrieveExpression
  def visitRetrieveExpression(ctx)
    visitRetrieve(ctx)
  end

  
  # | expression 'is' 'not'? ( 'null' | 'true' | 'false' )               # booleanExpression
  def visitBooleanExpression(ctx)

  end
 
  # | expression 'between' expressionTerm 'and' expressionTerm           # rangeExpression
  def visitRangeExpression(ctx)

  end
  # | ('years' | 'months' | 'days' | 'hours' | 'minutes' | 'seconds' | 'milliseconds') 'between' expressionTerm 'and' expressionTerm
  #                                                                      # timeRangeExpression

  def visitTimeRangeExpression(ctx)

  end

  # | expression ('<=' | '<' | '>' | '>=') expression                    # inequalityExpression
  def visitInequalityExpression(ctx)

  end
  # | expression ('=' | '<>') expression                                 # equalityExpression
  def visitEqualityExpression(ctx)

  end
 
 # : term                                                               # termExpressionTerm
  def visitTermExpressionTerm(ctx)
    ctx.term.accept(self)
  end

 def visitTermExpression(ctx)
     ctx.expression_term.accept(self)
  end

 
  def visitTerm(ctx)
    return ctx.IDENTIFIER.text if ctx.IDENTIFIER
    return ctx.literal.accept(self) if ctx.literal
    return ctx.expression.accept(self) if ctx.expression
  end

   
  # | expressionTerm '.' IDENTIFIER                                      # accessorExpressionTerm
  def visitAccessorExpressionTerm(ctx)

  end


  # | expressionTerm '(' (expression (',' expression)*)? ')'             # methodExpressionTerm
  def visitMethodExpressionTerm(ctx)
    puts "method"
    #needd to handle things like AgeAt here

  end
  # | expressionTerm '(' IDENTIFIER 'from' expression ')'                # methodFromExpressionTerm

  def visitMethodFromExpressionTerm(ctx)

  end
  
  # | ('start' | 'end') 'of' expressionTerm                              # timeBoundaryExpressionTerm

  def visitTimeBoundaryExpressionTerm(ctx)

  end
  # | ('date' | 'time' | 'year' | 'month' | 'day' | 'hour' | 'minute' | 'second' | 'millisecond') 'of' expressionTerm
  #                                                                      # timeUnitExpressionTerm
  def visitTimeUnitExpressionTerm(ctx)

  end
  # | 'duration' 'in' ('years' | 'months' | 'days' | 'hours' | 'minutes' | 'seconds' | 'milliseconds') 'of' expressionTerm
  #                                                                      # durationExpressionTerm
  def visitDurationExpressionTerm(ctx)

  end

  # | ('distinct' | 'collapse' | 'expand') expression                    # aggregateExpressionTerm
  def vistAggregateExpressionTerm(ctx)
    #only handle distinct for specific occurances
    #bomb out on others
  end
  # | ('union' | 'intersect') '(' expression (',' expression)+ ')'       # prefixSetExpressionTerm

  def visitPrefixSetExpressionTerm(ctx)
    #build a data criteria object that is a UNION or a XPRODUCT 
    #basically treate these as if they are just and and or blocks 
  end

  def visitLiteral(ctx)
      visitChildren(ctx)
  end

  def visitBooleanLiteral(ctx)
    ctx.text
  end

  def visitStringLiteral(ctx)
    ctx.STRING.text
  end

  def visitNullLiteral(ctx)
     nil
  end

  def visitQuantityLiteral(ctx)
     value = ctx.QUANTITY.text
     unit = ctx.unit.STRING.text if ctx.unit
     {value: value, units: units}
  end

  def handle_precondition(id,pre)
    v = visitChildren(pre)
    if !v.kind_of?(CQL::PreCondition)
      v = wrap_precondition(v)
    end
    @current_parsing_context[id] = v
    @preconditions[id] = v
    v
  end


  def handle_population(id, pop)
    v = visitChildren(pop)
    if !v.kind_of?(CQL::PreCondition)
      v = wrap_precondition(v)
    end
    @current_parsing_context[id] = v
    @populations[id] = v
    v
  end

  def reference_to_precondition(reference)
    pre = nil
    if reference.kind_of?(CQL::DataCriteria)
       pre =  CQL::PreCondition.new(next_id,nil,nil,reference.id)
    elsif reference.kind_of?(String)
      pre = @preconditions[reference] if @preconditions[reference] 
      pre = CQL::PreCondition.new(next_id,nil,nil,reference) if @data_criteria[reference]
      unless pre
        pre = CQL::PreCondition.new(next_id,nil,nil,reference)
        # need to setup something that finalizes this after parsing
      end
    end
    pre
  end

  def ensure_precondition(pre)
    pre.kind_of?(CQL::PreCondition) ? pre : reference_to_precondition(pre)
  end

  def wrap_precondition(pre)
    wrapped = CQL::PreCondition.new(next_id,"allTrue",[ensure_precondition(pre)],nil)
  end


  def parse_definition_and_status(type)
    settings = HQMF::DataCriteria.get_settings_map.values.select {|x| x['title'] == type.downcase}
    raise "multiple settings found for #{type}" if settings.length > 1
    settings = settings.first

    if (settings.nil?)
      parts = type.split(',')
      definition = parts[0].tr(':','').downcase.strip.tr(' ','_')
      status = parts[1].downcase.strip.tr(' ','_') if parts.length > 1
      settings = {'definition' => definition, 'status' => status}
    end

    definition = settings['definition']
    status = settings['status']

    # fix oddity with medication discharge having a bad definition
    if definition == 'medication_discharge'
      definition = 'medication'
      status = 'discharge'
    end 
    status = nil if status && status.empty?

    {definition: definition, status: status}
  end

  def format_id(value)
    value.gsub(/\W/,' ').split.collect {|word| word.strip.capitalize }.join
  end
end