module CQL
  # Used to represent 'any value' in criteria that require a value be present but
  # don't specify any restrictions on that value
  class AnyValue
    attr_reader :type
    
    def initialize(type='ANYNonNull')
      @type = type 
    end
    
    def to_model
      HQMF::AnyValue.new(@type)
    end    
  end
  
  # Represents a bound within a HQMF pauseQuantity, has a value, a unit and an
  # inclusive/exclusive indicator
  class Value
    include CQL::Utilities
    
    TIME_UNIT_TRANSLATION = { years: 'a', months: 'mo', weeks: 'wk', days: 'd', hours: 'h', minutes: 'min', seconds: 's'}
    OTHER_UNIT_TRANSLATION = { 'mmHg' => 'mm[Hg]', 'per mm3' => '/mm3', 'copies/mL' => '[copies]/mL', 'bpm' => '{H.B}/min'}

    attr_reader :type, :unit, :value
    
    def initialize(quantity, unit, inclusive, type='PQ')
      @type = type
      @value = quantity
      @inclusive = inclusive
      @unit = translate_unit(unit)
    end
    
    def derived?
      false
    end

    def inclusive?
      @inclusive
    end
    
    def expression
      nil
    end
    
    def to_model
      HQMF::Value.new(type,unit,value,inclusive?,derived?,expression)
    end

    def translate_unit(unit)
      unit = (TIME_UNIT_TRANSLATION[unit.downcase.to_sym] || unit) if unit
      unit = (OTHER_UNIT_TRANSLATION[unit] || unit) if unit
      unit
    end
  end
  
  # Represents a HQMF physical quantity which can have low and high bounds
  class Range
    include CQL::Utilities
    attr_accessor :type, :low, :high, :width
    
    def initialize(comparison, quantity, unit, type=nil)
      @type = type
      set_optional_value(comparison, quantity, unit)
    end
    
    def to_model
      lm = low ? low.to_model : nil
      hm = high ? high.to_model : nil
      HQMF::Range.new(type, lm, hm, nil)
    end
    
    private

    def set_optional_value(comparison, quantity, unit)
      comparison_data = translate_comparison(comparison)
      value = Value.new(quantity, unit, comparison_data[:inclusive], default_bounds_type)
      case comparison_data[:high_or_low]
      when :high
        @high = value
      when :low
        @low = value
      when :both
        @high = value
        @low = value
      end
    end

    def translate_comparison(comparison)
      case comparison.downcase
      when 'less than or equal to'
        {high_or_low: :high, inclusive: true}
      when 'less than'
        {high_or_low: :high, inclusive: false}
      when 'greater than or equal to'
        {high_or_low: :low, inclusive: true}
      when 'greater than'
        {high_or_low: :low, inclusive: false}
      when 'equal to'
        {high_or_low: :both, inclusive: true}
      else
        raise "unknown mode for attribute: #{comparison}"
      end
    end
    
    def default_bounds_type
      case type
      when 'IVL_TS'
        'TS'
      else
        'PQ'
      end
    end
  end
  
  # Represents a HQMF CD value which has a code and codeSystem
  class Coded
    include CQL::Utilities

    attr_reader :code_list_id, :title
    
    def initialize(code_list_id, title)
      @code_list_id = code_list_id
      @title = title
    end
    
    def to_model
      HQMF::Coded.for_code_list(code_list_id, title)
    end
    
  end
  
  class SubsetOperator
    include CQL::Utilities

    attr_reader :type, :value

    def initialize(type, value = nil)
      @type = translate_type(type)
      @value = value
    end

    def translate_type(type)
      type = 'RECENT' if type == 'MOST RECENT'
      type = 'MEAN' if type == 'AVG'
      raise "unknown subset operator type #{type}" unless HQMF::SubsetOperator::TYPES.include? type
      type
    end

    def to_model
      vm = value ? value.to_model : nil
      HQMF::SubsetOperator.new(type, vm)
    end
  end
  
  class TemporalReference
    include CQL::Utilities
    
    attr_accessor :type
    attr_reader :reference, :range

    def initialize(type, comparison, quantity, unit, reference)
      @type = translate_type(type)
      @range = CQL::Range.new(comparison, quantity, unit, 'IVL_PQ') if comparison
      @reference = Reference.new(reference.id)
    end

    def translate_type(type)
      # todo: we now have SBDU
      type = 'SBE' if type == 'SBOD'
      type = 'EBE' if type == 'EBOD'
      type = 'OVERLAP' if type == 'Overlaps'

      #raise "unknown temporal reference type #{type}" unless HQMF::TemporalReference::TYPES.include? type
      type
    end
    
    def to_model
      rm = range ? range.to_model : nil
      HQMF::TemporalReference.new(type, reference.to_model, rm)
    end  
  end

  # Represents a HQMF reference from a precondition to a data criteria
  class Reference
    include CQL::Utilities
    
    attr_accessor :id

    def initialize(id)
      @id = id
    end
    
    def to_model
      HQMF::Reference.new(@id)
    end
  end

  class Attribute
    attr_reader :id, :code_list_id, :title
    
    def initialize(id, code_list_id, title)
      @id = id
      @code_list_id = code_list_id
      @title = title
    end

    def self.translate_attribute(attribute, doc)
      mode = attribute.at_xpath('@mode').value
      case mode
      when 'Value Set'
        attribute_entry = doc.attribute_map[attribute.at_xpath('@qdmUUID').value]
        Coded.new(attribute_entry.code_list_id,attribute_entry.title)
      when 'Check if Present'
        AnyValue.new
      else
        quantity = attribute.at_xpath('@comparisonValue').value
        unit = attribute.at_xpath('@unit').try(:value)
        Utilities.build_value(mode, quantity, unit)
      end
    end
  end
  
end