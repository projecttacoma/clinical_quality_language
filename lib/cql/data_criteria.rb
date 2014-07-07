module CQL
  # Represents a data criteria specification
  class DataCriteria

    attr_accessor :id, :field_values, :value, :negation, :negation_code_list_id, :derivation_operator, :children_criteria, :subset_operators, :comments
    attr_reader :hqmf_id, :title, :display_name, :description, :code_list_id, 
        :definition, :status, :effective_time, :inline_code_list, 
        :temporal_references, :specific_occurrence, 
        :specific_occurrence_const, :source_data_criteria

    def initialize(data ={})
      data.each_pair do |k,v|
        instance_variable_set("@#{k}" , v)
      end
    end    
 
    def to_model

    end

    def derived?
      !@derivation_operator.nil? 
    end

    def dup
      dc = DataCriteria.new()
      self.instance_variables.each do |v|
        dc.instance_variable_set(v, self.instance_variable_get(v))
      end
      dc
    end

    def add_temporal(temporal)
      @temporal_references ||= []
      @temporal_references << temporal
    end
    
    def to_model

      trs = temporal_references.collect {|t| t.to_model} if temporal_references
      val = value.to_model if value
      HQMF::DataCriteria.new(@id, @title, @display_name, @description, @code_list_id, @children_criteria, 
        @derivation_operator, @definition, @status, val, fv, @effective_time, @inline_code_list, 
        @negation, @negation_code_list_id, trs, subs, @specific_occurrence, 
        @specific_occurrence_const, @source_data_criteria, comments)
    end

    def self.parse_retrieve(retrieve)
      text = retrieve.text()
      text.gsub!("[","").gsub("]","")
      topic = retrieve.topic().text()
      modality = retrieve.modality().text()
      valueset = retrieve.valueset().text()
      oid = @valuesets[valueset] || ""
      type = "#{topic}, #{modality}"
      _id = format_id(text)
      settings = {title: type, description: type, code_list_id: oid ,source_data_criteria: _id, id: _id, negation:false, display_name: type}
      settings.merge!(parse_definition_and_status(type))                                      
      DataCriteria.new(settings)
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