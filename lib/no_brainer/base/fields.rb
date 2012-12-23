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

  def initialize(attrs={})
    super
    @attributes = {}
    attrs.each do |k,v|
      __send__("#{k}=", v)
    end
  end

  # bypasses any attribute protection
  # TODO find a better name because it sounds like
  # initialize() doesn't get called
  def raw_initialize(attrs)
    super
    # TODO Should we reject undeclared fields ?
    @attributes = attrs
  end

  module ClassMethods
    def from_attributes(attrs)
      self.new.tap { |model| model.raw_initialize(attrs) } if attrs
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
