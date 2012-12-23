module NoBrainer::Base::Fields
  extend ActiveSupport::Concern

  # we want 'include ActiveModel::Serialization' eventually
  # (to_json, and friends)

  included do
    attr_accessor :attributes
    class_attribute :fields
    self.fields = []

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
      fields << name
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
