module Misc
  def permitted_attributes
    attrs = {}
    def attrs.permitted?
      true
    end
    attrs
  end

  def non_permitted_attributes
    attrs = {}
    def attrs.permitted?
      false
    end
    attrs
  end

  RSpec.configure { |config| config.include self }
end
