module NoBrainer::Criteria::Pluck
  extend ActiveSupport::Concern

  included { attr_accessor :missing_attributes }

  def pluck(*attrs)
    _missing_attributes_criteria(:pluck, attrs)
  end

  def without(*attrs)
    _missing_attributes_criteria(:without, attrs)
  end

  def merge!(criteria, options={})
    return super unless criteria.missing_attributes

    self.missing_attributes ||= {}
    criteria.missing_attributes.each do |type, attrs|
      old_attrs = self.missing_attributes[type] || {}.with_indifferent_access
      new_attrs = old_attrs.deep_merge(attrs)
      new_attrs = new_attrs.select { |k,v| v } # TODO recursive
      self.missing_attributes[type] = new_attrs
      self.missing_attributes.delete(type) if new_attrs.empty?
    end
  end

  private

  def effective_missing_attributes
    return nil if missing_attributes.nil?
    @effective_missing_attributes ||= begin
      # pluck gets priority
      type = if    self.missing_attributes[:pluck]   then :pluck
             elsif self.missing_attributes[:without] then :without
             end
      { type => self.missing_attributes[type] } if type
    end
  end

  def instantiate_model(attrs, options={})
    super(attrs, options.merge(:missing_attributes => effective_missing_attributes))
  end

  def _missing_attributes_criteria(type, args)
    raise ArgumentError if args.size.zero?
    args = [Hash[args.flatten.map { |k| [k, true] }]] unless args.size == 1 && args.first.is_a?(Hash)
    chain { |criteria| criteria.missing_attributes = {type => args.first} }
  end

  def compile_rql_pass2
    rql = super
    if effective_missing_attributes
      type, attrs = effective_missing_attributes.first
      rql = rql.__send__(type, klass.with_fields_aliased(attrs))
    end
    rql
  end
end
