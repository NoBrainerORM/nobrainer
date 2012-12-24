module ModelsHelper
  def load_models
    define_constant :BasicModel, NoBrainer::Base do
      field :field1
      field :field2
      field :field3
    end
  end

  def load_blog_models
    define_constant :Post, NoBrainer::Base do
      field :title
      field :body

      has_many :comments
    end

    define_constant :Comment, NoBrainer::Base do
      field :author
      field :body

      belongs_to :post
    end
  end
end
