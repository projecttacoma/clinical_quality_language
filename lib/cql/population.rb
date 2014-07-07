module CQL
  class Population
    attr_accessor :type, :title, :conjunction, :hqmf_id, :preconditions
  end

  def initialize(type,preconditions=[])
    @type= type
    @preconditions = preconditions
  end


end
