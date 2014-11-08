module ModelsHelper
  def load_simple_document
    define_class :SimpleDocument do
      include NoBrainer::Document

      field :field1
      field :field2
      field :field3
    end
  end

  def load_blog_models
    define_class :Author do
      include NoBrainer::Document

      field :author

      has_many :posts
    end

    define_class :Post do
      include NoBrainer::Document

      field :title
      field :body

      belongs_to :author
      has_many :comments
    end

    define_class :Comment do
      include NoBrainer::Document

      field :author
      field :body

      belongs_to :post
    end
  end

  def load_polymorphic_models
    define_class :Parent do
      include NoBrainer::Document
      field :parent_field
    end

    define_class :Child, Parent do
      field :child_field
    end

    define_class :GrandChild, Child do
      field :grand_child_field
    end
  end
end
