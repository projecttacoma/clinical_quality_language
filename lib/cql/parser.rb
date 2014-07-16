module CQL
  class Parser <  org.cqframework.cql.gen.cqlBaseVisitor

    include CQL::Utilities

    attr_accessor :doc
    attr_accessor :valuesets
    attr_accessor :data_criteria
    attr_accessor :source_data_criteria
    attr_accessor :preconditions
    attr_accessor :populations
    attr_accessor :parameters
    attr_accessor :dc_ids


    def initialize
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

    def reset
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

    def parse(file,hqmf_id=UUID.generate,hqmf_set_id=UUID.generate,hqmf_version_number="0",cms_id="CMS00v0",title="title",description="description")
      reset
      set_default_criteria
      includeFile(file)
      dcs = data_criteria.values.compact.collect {|dc| dc.to_model}
      pcs = populations.values.compact.collect {|pc| pc.to_model}
      sdc = source_data_criteria.values.compact.collect{|dc| dc.to_model}
      HQMF::Document.new("", hqmf_id, hqmf_set_id, hqmf_version_number, cms_id, title, description, pcs, dcs, sdc, [], measure_period, get_populations)
    end

    def parseData(data,hqmf_id=UUID.generate,hqmf_set_id=UUID.generate,hqmf_version_number="0",cms_id="CMS00v0",title="title",description="description")
      reset
      set_default_criteria
      includeData(data)
      dcs = data_criteria.values.compact.collect {|dc| dc.to_model}
      pcs = populations.values.compact.collect {|pc| pc.to_model}
      sdc = source_data_criteria.values.compact.collect{|dc| dc.to_model}
      HQMF::Document.new("", hqmf_id, hqmf_set_id, hqmf_version_number, cms_id, title, description, pcs, dcs, sdc, [], measure_period, get_populations)
    end

    def get_populations()
      pops = [{"title"=>"Population1","id"=>"Population1"}]

      @populations.keys.each do |k|
        pops[0][k] = k
      end
      pops
    end

    def measure_period
      r = HQMF::Range.from_json({
                                  'type' => "IVL_TS",
                                  'low' => { 'type' => "TS", 'value' => "201201010000", 'inclusive?' => true, 'derived?' => false },
                                  'high' => { 'type' => "TS", 'value' => "201212312359", 'inclusive?' => true, 'derived?' => false },
                                  'width' => { 'type' => "PQ", 'unit' => "a", 'value' => "1", 'inclusive?' => true, 'derived?' => false }
      });
    end

    def set_default_criteria
      ethnicity = CQL::DataCriteria.new( {"title" => "Ethnicity",
            "description" => "Patient Characteristic Ethnicity: Ethnicity",
            "code_list_id" => "2.16.840.1.114222.4.11.837",
            "definition" => "patient_characteristic_ethnicity",
            "source_data_criteria" => "PatientCharacteristicEthnicityEthnicity",
            "id" =>"PatientCharacteristicEthnicityEthnicity"})
      race = CQL::DataCriteria.new( {"title" => "Race",
            "description" => "Patient Characteristic Race: Race",
            "code_list_id" => "2.16.840.1.114222.4.11.836",
            "definition" => "patient_characteristic_race",
            "source_data_criteria" => "PatientCharacteristicRaceRace",
            "id" =>"PatientCharacteristicRaceRace"})
      gender = CQL::DataCriteria.new( {"title" => "Gender",
            "description" => "Patient Characteristic Gender: Gender",
            "code_list_id" => "2.16.840.1.113762.1.4.1",
            "definition" => "patient_characteristic_gender",
            "source_data_criteria" => "PatientCharacteristicGenderGender",
            "id" =>"PatientCharacteristicGenderGender"})
      payer = CQL::DataCriteria.new( {"title" => "Payer",
            "description" => "Patient Characteristic Payer: Payer",
            "code_list_id" => "2.16.840.1.114222.4.11.3591",
            "definition" => "patient_characteristic_payer",
            "source_data_criteria" => "PatientCharacteristicPayerPayer",
            "id" =>"PatientCharacteristicPayerPayer"})
      birthdate = CQL::DataCriteria.new( {"title" => "Birthdate",
            "description" => "Patient Characteristic Birthdate: birth date",
            "code_list_id" => "2.16.840.1.113883.3.560.100.4",
            "definition" => "patient_characteristic_birthdate",
            "source_data_criteria" => "PatientCharacteristicBirthdateBirthDate",
            "id" =>"PatientCharacteristicBirthdateBirthDate"})

      @source_data_criteria["PatientCharacteristicBirthdateBirthDate"] = birthdate
      @source_data_criteria["PatientCharacteristicEthnicityEthnicity"] = ethnicity
      @source_data_criteria["PatientCharacteristicRaceRace"] = race
      @source_data_criteria["PatientCharacteristicGenderGender"] = gender
      @source_data_criteria["PatientCharacteristicPayerPayer"] = payer
      @source_data_criteria["Gender"] = gender

      @data_criteria["PatientCharacteristicBirthdateBirthDate"] = birthdate.dup
      @data_criteria["PatientCharacteristicEthnicityEthnicity"] = ethnicity.dup
      @data_criteria["PatientCharacteristicRaceRace"] = race.dup
      @data_criteria["PatientCharacteristicGenderGender"] = gender.dup
      @data_criteria["PatientCharacteristicPayerPayer"] = payer.dup
      @data_criteria["Gender"] = @data_criteria["PatientCharacteristicGenderGender"]

    end

    def includeFile(file)
      includeData(File.read(file))
    end

    def includeData(data)
      input =  ANTLRInputStream.new(data);
      lexer =  CQL_LEXER.new(input)
      tokens = CommonTokenStream.new(lexer)
      parser = CQL_PARSER.new(tokens)
      parser.setBuildParseTree(true)
      tree = parser.logic()
      visit(tree)
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

    def visitParameter(ctx)

    end

    def visitInclude(ctx)
      includeFile(ctx.IDENTIFIER.text)
    end

    # | expression ('or' | 'xor') expression                               # orExpression
    def visitOrExpression(ctx)
      handlePrecondition(ctx,"atLeastOneTrue")
    end

    # | expression 'and' expression                                        # andExpression
    def visitAndExpression(ctx)
      handlePrecondition(ctx, "allTrue")
    end

    def handleGrouper(ctx,operator)
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
      ext1 = ctx.expression(0).accept(self)
      obj = resolve(ext1)
      precondition = CQL::PreCondition.new(next_id, operator,[],nil)
      if (!obj.kind_of?(CQL::PreCondition) && !obj.kind_of?(CQL::Population)) || (obj.kind_of?(CQL::PreCondition) && obj.conjunction_code != operator)
          precondition.preconditions << ensure_precondition(obj,operator)
      else
        precondition = obj if !obj.kind_of?(CQL::Population)
      end
      # #make sure its not a population
      exp2 = ctx.expression(1).accept(self)
      obj2 = resolve(exp2)
      if !obj2.kind_of?(CQL::Population)
        precondition.preconditions << ensure_precondition(obj2,operator)
      end

      precondition
    end

    def resolve(ref)
      obj = ref
      if ref.kind_of?(String)
        obj = @data_criteria[ref]
        obj = @preconditions[ref] if obj.nil?
        obj = @populations[ref] if obj.nil?
      end
      obj
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
      # get the dc and what its involving
      # get the interval
      # get the assocaited dc
      # create the temporal reference on the first dc
      left_fields = ctx.expression(0).accept(self)
      right_fields = ctx.expression(1).accept(self)
      temporal_code,range = ctx.interval_operator_phrase.accept(self)

      left = nil
      if left_fields.kind_of?(Hash)
        left = left_fields[:data_criteria]
      elsif left_fields.kind_of?(CQL::DataCriteria)
        left = left_fields
      elsif left_fields.kind_of?(String)
        left = @current_parsing_context[left_fields]
      end

      raise "Unknown identifier #{left_fields}" unless left

      right = nil
      if right_fields.kind_of?(Hash)
        right = right_fields[:data_criteria].kind_of?(CQL::DataCriteria) ? right_fields[:data_criteria].id : right_fields[:data_criteria]
      elsif right_fields.kind_of?(CQL::DataCriteria)
        right = right_fields.id
      elsif right_fields.kind_of?(String)
        right = right_fields
      end

      temporal_reference = CQL::TemporalReference.new(temporal_code, nil, nil, nil, CQL::Reference.new(right))
      left.temporal_references ||= []
      left.temporal_references << temporal_reference
      temporal_reference
    end

    # return the temporal code and range for the phrase
    def visitIntervalOperatorPhrase(ctx)

      code = CQL::Utilities::TIMING_CODE_MAPPING[ctx.text]
      return code, nil if code
      # if we do not have a mapping for the timing then this contains a qauntity or we blow up
      ql = ctx.quantity_literal.accept(this) if ctx.quantity_literal
      qo =  ctx.quantity_offset.accept(this) if ctx.quantity_offset
      unless ql || qo
        raise "Interval not supported #{ctx.text}"
      end

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
      sdc.precondition_id = next_id
      return sdc,_alias
    end

    # | aliasedQuerySource queryInclusionClause* ('where' expression)? ('return' expression)? ('sort' 'by' sortByItem (',' sortByItem)*)?
    #                                                                      # queryExpression
    def visitQueryExpression(ctx)
      _context = @current_parsing_context
      @current_parsing_context = _context.dup
      dc,_alias = ctx.aliased_query_source.accept(self)
      @current_parsing_context[_alias]=dc
      @data_criteria[dc.id] = dc
      visit(ctx.expression(0))
      @current_parsing_context = _context
      dc
    end

    def visitValuesetDefinition(vs)
      # get the identifier and the oid for the vs and add it to the cache
      name = vs.STRING().text()
      oid = vs.expression().text().gsub('ValueSet("',"").gsub('")',"")
      @valuesets[name] = oid
    end

    def visitLetStatement(let)
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
        text.gsub!("[","").gsub!("]","").gsub!('"',"").gsub!(":",": ")
        topic = retrieve.topic().text().underscore
        modality = retrieve.modality().text() if retrieve.modality()
        valueset = retrieve.valueset().text()
        oid = @valuesets[valueset] 
        raise "Attempted to use undeclared valueset #{valueset}" unless oid
        type = (topic && modality) ? "#{topic}, #{modality}" : topic
        _id = format_id(text)
        settings = parse_definition_and_status(type)
        settings.merge!({title: type, description: text, code_list_id: oid ,source_data_criteria: _id, id: _id, negation:false, display_name: type})
        dc = CQL::DataCriteria.new(settings)
        @source_data_criteria[text] = dc
        @data_criteria[text] = dc.dup
      end
      @source_data_criteria[text]
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
      if ctx.expression[0].text.match(/AgeAt\(.*\)/)
        return handleAgeAtExpression(ctx)
      else
        raise "equalityExpression only implemented for Gender"
      end
    end
    # | expression ('=' | '<>') expression                                 # equalityExpression
    def visitEqualityExpression(ctx)
      if ctx.expression[0].text == "Gender"
        return handleGender(ctx)
      else
        raise "equalityExpression only implemented for Gender"
      end

    end

    def handleGender(ctx)
      sdc = nil
      
      value = ctx.expression[1].text.gsub('"',"")
      gender = {"male"=>"M","female"=>"F"}[value] || value
      raise "Only M,F values supported as Gender" if (!["M","F"].index(gender))
      dc = genderCriteria(gender)
      dc.precondition_id=next_id
      dc.negation = ctx.children[1].text == "<>"
      @data_criteria[dc.id] = dc
      dc
    end

    def genderCriteria(gender)
      title = gender == "F" ? "Female" : "Male"
      dc = @data_criteria["PatientCharacteristicSex#{title}"]
      return dc.dup if dc
      sdc = nil
      if gender == "F"
        sdc = CQL::DataCriteria.new({"definition" => "patient_characteristic_gender",
                                    "title" =>"Female",
                                    "id"=>"PatientCharacteristicSexFemale",
                                    "source_data_criteria" =>"PatientCharacteristicSexFemale",
                                    "description"=>"Patient Characteristic Sex: Female",
                                    "code_list_id" => "2.16.840.1.113883.3.560.100.2"})
      else
        sdc = CQL::DataCriteria.new({"definition" => "patient_characteristic_gender",
                                    "title" =>"Male",
                                    "id"=>"PatientCharacteristicSexMale",
                                    "source_data_criteria" =>"PatientCharacteristicSexMale",
                                    "description"=>"Patient Characteristic Sex: Male",
                                    "code_list_id" => "2.16.840.1.113883.3.560.100.1"})
      end
      sdc.value=CQL::Coded.new("CD","Gender",gender,nil)
      @source_data_criteria[sdc.id] = sdc
      @data_criteria[sdc.id] = sdc.dup
      sdc.dup 
    end

    # This will except inEquality expressions 
    def handleAgeAtExpression(ctx)
      dc = @data_criteria["PatientCharacteristicBirthdateBirthDate"].dup
      dc.precondition_id=next_id
      code = (ctx.expression[0].text=="AgeAt(startofMeasurePeriod)") ? "SBS" : "SBE"
      quantity = ctx.expression[1].text
      temporal_reference = CQL::TemporalReference.new(code, ctx.children[1].text, quantity, "a", CQL::Reference.new("MeasurePeriod"))
      dc.temporal_references = [ temporal_reference]
      @data_criteria[dc.id]=dc
      dc
    end

    def parseAgeAtMethod(ctx)

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
      return {data_criteria: @current_parsing_context[ctx.expressionTerm.text] || ctx.expressionTerm.text, field: ctx.IDENTIFIER.text}
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
      pre = []
      if (v.kind_of?(String) && !@populations[v]) || v.kind_of?(CQL::DataCriteria)
        pre << wrap_precondition(v)
      elsif v.kind_of?(CQL::PreCondition)
        pre << v
      end
      pop = CQL::Population.new(id,pre)

      @current_parsing_context[id] = pop
      @populations[id] = pop
      pop
    end

    def reference_to_precondition(reference,operator="allTrue")
      pre = nil
      if reference.kind_of?(CQL::DataCriteria)
        pre =  CQL::PreCondition.new(next_id,operator,nil,reference.id)
      elsif reference.kind_of?(String)
        pre = @preconditions[reference] if @preconditions[reference]
        pre = CQL::PreCondition.new(next_id,operator,nil,reference) if @data_criteria[reference]
        if pre.nil? && !@populations[reference]
          pre = CQL::PreCondition.new(next_id,operator,nil,reference)
          # need to setup something that finalizes this after parsing
        end
      end
      pre
    end

    def ensure_precondition(pre,operator="allTrue")
      pre.kind_of?(CQL::PreCondition) ? pre : reference_to_precondition(pre,operator)
    end

    def wrap_precondition(pre)
      enpre = ensure_precondition(pre)
      children = []
      children << enpre if enpre
      wrapped = CQL::PreCondition.new(next_id,"allTrue",children,nil)
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
end
