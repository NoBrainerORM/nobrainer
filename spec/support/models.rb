module ModelsHelper
  def load_simple_document
    define_constant :SimpleDocument do
      include NoBrainer::Document

      field :field1
      field :field2
    end
  end

  def load_blog_models
    define_constant :Post do
      include NoBrainer::Document

      field :title
      field :body

      has_many :comments
    end

    define_constant :Comment do
      include NoBrainer::Document

      field :author
      field :body

      belongs_to :post
    end
  end
end
