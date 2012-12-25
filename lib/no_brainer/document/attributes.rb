module NoBrainer::Document::Attributes
  extend ActiveSupport::Concern

  # TODO test these serialization includes
  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  included do
    include ActiveModel::MassAssignmentSecurity
    attr_accessor :attributes
    field :id
  end

  def initialize(attrs={}, options={})
    super
    assign_attributes(attrs, options.reverse_merge(:prestine => true))
  end

  def assign_attributes(attrs, options={})
    if options[:prestine]
      # TODO FIXME Not setting attributes to {} because
      # RethinkDB gives us some "missing attribute" on queries.
      @attributes = Hash[(self.class.fields.keys - [:id]).map { |f| [f.to_s, nil] }]
      clear_internal_cache
    end

    # TODO Should we reject undeclared fields ?
    if options[:from_db]
      @attributes.merge! attrs
    else
      unless options[:without_protection]
        attrs = sanitize_for_mass_assignment(attrs, options[:as])
      end
      attrs.each { |k,v| __send__("#{k}=", v) }
    end
  end

  # TODO test that thing
  def inspect
    attrs = self.class.fields.keys.map { |f| "#{f}: #{@attributes[f.to_s].inspect}" }
    "#<#{self.class} #{attrs.join(', ')}>"
  end

  module ClassMethods
    def new_from_db(attrs, options={})
      new(attrs, options.reverse_merge(:from_db => true)) if attrs
    end

    def inherited(subclass)
      # TODO FIXME when the parent adds new fields, the subclasses
      # will not get them
      parent_fields = @fields.dup
      subclass.class_eval do
        @fields = parent_fields
      end
    end

    def fields
      @fields
    end

    def field(name, options={})
      name = name.to_sym
      @fields ||= {}
      @fields[name] = true

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
