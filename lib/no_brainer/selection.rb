class NoBrainer::Selection
  attr_accessor :selection

  def initialize(selection)
    self.selection = selection
  end

  def count
    NoBrainer.run { selection.count }
  end
end
