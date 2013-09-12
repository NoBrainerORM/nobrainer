module NoBrainer::Document::Attributes
  extend ActiveSupport::Concern

  included do
    if NoBrainer.rails3?
      include ActiveModel::MassAssignmentSecurity
    end
    attr_accessor :attributes

    # Not using class_attribute because we want to
    # use our custom logic
    class << self; attr_accessor :fields; end
    self.fields = {}
  end

  def initialize(attrs={}, options={})
    super
    assign_attributes(attrs, options.reverse_merge(:prestine => true))
  end

  def reset_attributes
    # XXX Performance optimization: we don't save field that are not
    # explicitly set. The row will therefore not contain nil for
    # unset attributes. This has some implication when using where()
    # see lib/no_brainer/selection/where.rb
    self.attributes = {}
  end

  def assign_attributes(attrs, options={})
    reset_attributes if options[:prestine]

    # TODO Should we reject undeclared fields ?
    if options[:from_db]
      attributes.merge! attrs
    else
      if NoBrainer.rails3?
        unless options[:without_protection]
          attrs = sanitize_for_mass_assignment(attrs, options[:as])
        end
      end
      attrs.each { |k,v| __send__("#{k}=", v) }
    end
  end
  alias_method :attributes=, :assign_attributes

  # TODO test that thing
  def inspect
    attrs = self.class.fields.keys.map { |f| "#{f}: #{attributes[f.to_s].inspect}" }
    "#<#{self.class} #{attrs.join(', ')}>"
  end

  module ClassMethods
    def new_from_db(attrs, options={})
      klass_from_attrs(attrs).new(attrs, options.reverse_merge(:from_db => true)) if attrs
    end

    def inherited(subclass)
      super
      subclass.fields = self.fields.dup
    end

    def field(name, options={})
      name = name.to_sym

      # Using a hash because:
      # - at some point, we want to associate informations with a field (like the type)
      # - it gives us a set for free
      ([self] + descendants).each do |klass|
        klass.fields[name] = true
      end

      # Using a layer so the user can use super when overriding these methods
      inject_in_layer :attributes, <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}=(value)
          attributes['#{name}'] = value
        end

        def #{name}
          attributes['#{name}']
        end
      RUBY
    end
  end
end
