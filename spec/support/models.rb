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
    
    define_class :Columnist do
      include NoBrainer::Document

      field :last_name
      field :employee_id

      has_many :articles, primary_key: :employee_id
    end

    define_class :Article do
      include NoBrainer::Document

      field :title
      field :slug
      field :body

      belongs_to :columnist, primary_key: :employee_id
      has_many :notes, class_name: 'Footnote', foreign_key: :article_slug_url, primary_key: :slug
    end

    define_class :Footnote do
      include NoBrainer::Document

      field :body

      belongs_to :article, foreign_key: :article_slug_url, primary_key: :slug
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

  RSpec.configure { |config| config.include self }
end
