module NoBrainer::Base::Fields
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Serialization
    attr_accessor :attributes
    field :id
  end

  def initialize(attrs={})
    super
    @attributes = {}
    attrs.each do |k,v|
      __send__("#{k}=", v)
    end
  end

  module ClassMethods
    def field(name, options={})
      class_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}=(value)
          @attributes['#{name}'] = value
        end

        def #{name}
          @attributes['#{name}']
        end
      RUBY
    end
  end
end
