# frozen_string_literal: true

require 'yaml'

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

  def load_album_models
    define_class :Album do
      include NoBrainer::Document

      field :slug, :primary_key => true

      has_many :pictures
    end

    define_class :Picture do
      include NoBrainer::Document

      belongs_to :album, :primary_key => :slug
    end
  end

  def load_columnist_models
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

  def load_store_accessor_document
    define_class :Coder do
      def initialize(default = {})
        @default = default
      end

      def dump(o)
        ActiveSupport::JSON.encode(o || @default)
      end

      def load(s)
        s.present? ? ActiveSupport::JSON.decode(s) : @default.clone
      end
    end

    define_class :AdminUser do
      include NoBrainer::Document

      field :name
      field :parent_name
      field :partner_name
      field :partner_birthday

      store :params, accessors: [:token], coder: YAML
      store :settings, accessors: %i[color homepage]
      store_accessor :settings, :favorite_food
      store :parent, accessors: %i[birthday name], prefix: true
      store :spouse, accessors: [:birthday], prefix: :partner
      store_accessor :spouse, :name, prefix: :partner
      store :configs, accessors: [:secret_question]
      store :configs, accessors: [:two_factor_auth], suffix: true
      store_accessor :configs, :login_retry, suffix: :config
      store :preferences, accessors: [:remember_login]
      store :json_data, accessors: %i[height weight], coder: Coder.new
      store :json_data_empty, accessors: [:is_a_good_guy], coder: Coder.new

      def phone_number
        read_store_attribute(:settings, :phone_number).gsub(/(\d{3})(\d{3})(\d{4})/, '(\1) \2-\3')
      end

      def phone_number=(value)
        write_store_attribute(:settings, :phone_number, value && value.gsub(/[^\d]/, ''))
      end

      def color
        super || 'red'
      end

      def color=(value)
        value = 'blue' unless %w[black red green blue].include?(value)
        super
      end
    end
  end

  def load_belongs_to_polymorphic_models
    define_class :IdentifiedPerson do
      include NoBrainer::Document

      field :fullname

      belongs_to :picture
    end

    define_class :Image do
      include NoBrainer::Document

      field :mime

      belongs_to :imageable, polymorphic: true
    end

    define_class :Logo, Image do
      include NoBrainer::Document
    end

    define_class :Picture, Image do
      include NoBrainer::Document

      has_many :people, class_name: 'IdentifiedPerson'
    end

    define_class :Event do
      include NoBrainer::Document

      belongs_to :restaurant
      has_many :photos, class_name: 'Picture', as: :imageable
      has_many :people, through: :photos
    end

    define_class :Restaurant do
      include NoBrainer::Document

      has_one :logo, as: :imageable
      has_many :pictures, as: :imageable
      has_many :events
      has_many :photos, through: :events
    end
  end

  RSpec.configure { |config| config.include self }
end
