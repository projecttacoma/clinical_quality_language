module CQL
  class PreCondition
    attr_accessor :id, :preconditions, :reference, :conjunction_code, :negation

    def initialize(_id = nil, conjunction_code = "allTrue", preconditions = [], reference=nil)
      @preconditions =preconditions
      @conjunction_code=conjunction_code
      @reference = reference.kind_of?(String) ? CQL::Reference.new(reference) : reference
      @id = _id
      @negation=false
    end

    def to_model
      pcs = preconditions.compact.collect {|p| p.to_model} if preconditions
      mr = reference.to_model if reference.kind_of?(CQL::Reference)
      mr = HQMF::Reference.new(reference) if !mr && reference.kind_of?(String)
      mr =reference
      HQMF::Precondition.new(id, pcs, mr, conjunction_code, negation)
    end

  end
end