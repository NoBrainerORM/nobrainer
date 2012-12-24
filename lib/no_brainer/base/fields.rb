module NoBrainer::Base::Fields
  extend ActiveSupport::Concern

  # TODO we want to 'include ActiveModel::Serialization'
  # eventually to get to_json, and friends.

  included do
    attr_accessor :attributes
    class_attribute :fields
    self.fields = []

    field :id
  end

  def initialize(attrs={}, options={})
    super
    assign_attributes(attrs, options.merge(:prestine => true))
  end

  def assign_attributes(attrs, options={})
    @attributes = {} if options[:prestine]
    attrs.each do |k,v|
      # TODO Should we reject undeclared fields ?
      __send__("#{k}=", v)
    end
  end

  module ClassMethods
    def from_attributes(attrs, options={})
      new(attrs, options) if attrs
    end

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
