module CQL
  # Represents a data criteria specification
  class DataCriteria

    attr_accessor :id, :field_values, :value, :negation, :negation_code_list_id, :derivation_operator, 
        :children_criteria, :subset_operators, :comments,:hqmf_id, :title, :display_name, :description,  
        :code_list_id, :definition, :status, :effective_time, :inline_code_list, :temporal_references,
        :specific_occurrence, :specific_occurrence_const, :source_data_criteria, :precondition_id

    def initialize(data ={})
      data.each_pair do |k,v|
        instance_variable_set("@#{k}" , v)
      end
    end    
 
    def precondition_id=(pre_id)
      @precondition_id = pre_id
      self.id = "#{self.id}_precondition_#{pre_id}"
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
        @derivation_operator, @definition, @status, val, nil, @effective_time, @inline_code_list, 
        @negation, @negation_code_list_id, trs, nil, @specific_occurrence, 
        @specific_occurrence_const, @source_data_criteria, comments)
    end

    
  end
end