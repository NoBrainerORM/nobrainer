module NoBrainer::Base::Attributes
  extend ActiveSupport::Concern

  # TODO we want to 'include ActiveModel::Serialization'
  # eventually to get to_json, and friends.

  included do
    attr_accessor :attributes
    field :id
  end

  def initialize(attrs={}, options={})
    super
    assign_attributes(attrs, options.merge(:prestine => true))
  end

  def assign_attributes(attrs, options={})
    if options[:prestine]
      @attributes = {}
      clear_internal_cache
    end

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
      inject_in_layer :attributes, <<-RUBY, __FILE__, __LINE__ + 1
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
