module CQL
  class PreCondition
    attr_accessor :id, :preconditions, :reference, :conjuntion_code

    def initialize(_id = nil, conjuntion_code = "allTrue", preconditions = [], reference=nil)
      @preconditions =preconditions
      @conjuntion_code=conjuntion_code
      @reference = reference
      @id = _id
    end
  end
end