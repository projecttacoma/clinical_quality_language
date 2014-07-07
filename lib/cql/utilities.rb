module CQL
  module Utilities
   TIMING_CODE_MAPPING = {"starts before start" => "SBS",
     "starts after start" => "SAS",
     "starts during" => "SDU",
     "starts before end" => "SBE",
     "starts after end" => "SAE",
     "starts concurrent start" => "SCWS",
     "starts concurrent end" => "SCWE",
     "starts concurrent" => "SCW",
     "overlaps" => "overlaps"
    }

    include HQMF::Conversion::Utilities
    
    # Utility function to handle optional attributes
    # @param xpath an XPath that identifies an XML attribute
    # @return the value of the attribute or nil if the attribute is missing
    def attr_val(xpath)
      Utilities::attr_val(@entry, xpath)
    end
    
    # Utility function to handle optional attributes
    # @param xpath an XPath that identifies an XML attribute
    # @return the value of the attribute or nil if the attribute is missing
    def self.attr_val(node, xpath)
      attr = node.at_xpath(xpath)
      if attr
        attr.value
      else
        nil
      end
    end
    
    def children_of(node)
      node.xpath('*[not(self::text|self::comment)]')
    end

    def comments_on(node)
      node.xpath('comment').map {|c| Utilities.attr_val(c, '@displayName')}
    end

    def self.build_value(comparison, quantity, unit)
      return nil if !comparison || !quantity
      unit = nil if unit && unit.strip.empty?
      if comparison.downcase == 'equal to'
        Value.new(quantity, unit, true)
      else
        Range.new(comparison, quantity, unit)
      end
    end

    MEASURE_ATTRIBUTES_MAP = {
      copyright: {"id"=>"COPYRIGHT", "code"=>"COPY", "name"=>"Copyright"},
      scoring: {"id"=>"MEASURE_SCORING", "code"=>"MSRSCORE", "name"=>"Measure Scoring"},
      types: {"id"=>"MEASURE_TYPE", "code"=>"MSRTYPE", "name"=>"Measure Type"},
      stratification: {"id"=>"STRATIFICATION", "code"=>"STRAT", "name"=>"Stratification"},
      riskAdjustment: {"id"=>"RISK_ADJUSTMENT", "code"=>"MSRADJ", "name"=>"Risk Adjustment"},
      aggregation: {"id"=>"RATE_AGGREGATION", "code"=>"MSRAGG", "name"=>"Rate Aggregation"},
      rationale: {"id"=>"RATIONALE", "code"=>"RAT", "name"=>"Rationale"},
      recommendations: {"id"=>"CLINICAL_RECOMMENDATION_STATEMENT", "code"=>"CRS", "name"=>"Clinical Recommendation Statement"},
      improvementNotations: {"id"=>"IMPROVEMENT_NOTATION", "code"=>"IDUR", "name"=>"Improvement Notation"},
      nqfid: {"id"=>"NQF_ID_NUMBER", "code"=>"OTH", "name"=>"NQF ID Number"},
      disclaimer: {"id"=>"DISCLAIMER", "code"=>"DISC", "name"=>"Disclaimer"},
      emeasurei: {"id"=>"EMEASURE_IDENTIFIER", "code"=>"OTH", "name"=>"eMeasure Identifier"},
      references: {"id"=>"REFERENCE", "code"=>"REF", "name"=>"Reference"},
      definitions: {"id"=>"DEFINITION", "code"=>"DEF", "name"=>"Definition"},
      guidance: {"id"=>"GUIDANCE", "code"=>"GUIDE", "name"=>"Guidance"},
      transmissionFormat: {"id"=>"TRANSMISSION_FORMAT", "code"=>"OTH", "name"=>"Transmission Format"},
      initialPatientPopDescription: {"id"=>"INITIAL_PATIENT_POPULATION", "code"=>"IPP", "name"=>"Initial Patient Population"},
      denominatorDescription: {"id"=>"DENOMINATOR", "code"=>"DENOM", "name"=>"Denominator"},
      denominatorExclusionsDescription: {"id"=>"DENOMINATOR_EXCLUSIONS", "code"=>"OTH", "name"=>"Denominator Exclusions"},
      numeratorDescription: {"id"=>"NUMERATOR", "code"=>"NUMER", "name"=>"Numerator"},
      numeratorExclusionsDescription: {"id"=>"NUMERATOR_EXCLUSIONS", "code"=>"OTH", "name"=>"Numerator Exclusions"},
      denominatorExceptionsDescription: {"id"=>"DENOMINATOR_EXCEPTIONS", "code"=>"DENEXCEP", "name"=>"Denominator Exceptions"},
      measurePopulationDescription: {"id"=>"MEASURE_POPULATION", "code"=>"MSRPOPL", "name"=>"Measure Population"},
      measureObservationsDescription: {"id"=>"MEASURE_OBSERVATIONS", "code"=>"OTH", "name"=>"Measure Observations"},
      supplementalData: {"id"=>"SUPPLEMENTAL_DATA_ELEMENTS", "code"=>"OTH", "name"=>"Supplemental Data Elements"}
    }

  end
end  