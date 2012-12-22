module ModelsHelper
  def load_models
    define_constant :BasicModel, NoBrainer::Base do
      field :field1
      field :field2
      field :field3
    end
  end
end
