module CQL
  class Population
    attr_accessor :id, :type, :title, :conjunction, :hqmf_id, :preconditions
    TITLES = {
      HQMF::PopulationCriteria::IPP => 'Initial Patient Population',
      HQMF::PopulationCriteria::DENOM => 'Denominator',
      HQMF::PopulationCriteria::NUMER => 'Numerator',
      HQMF::PopulationCriteria::DENEXCEP => 'Denominator Exception',
      HQMF::PopulationCriteria::DENEX => 'Denominator Exclusion',
      HQMF::PopulationCriteria::MSRPOPL => 'Measure Population',
      HQMF::PopulationCriteria::OBSERV => 'Measure Observation'
    }

    def initialize(type,preconditions=[])
      @type= type
      @id=type
      @title=TITLES[@type]
      @hqmf_id=@type
      @preconditions = preconditions
    end

    def to_model
        mps = preconditions.collect {|p| p.to_model}
        HQMF::PopulationCriteria.new(id, hqmf_id, type, mps, title, nil)
    end

  end
end
