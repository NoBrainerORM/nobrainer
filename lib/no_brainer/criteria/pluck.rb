module NoBrainer::Criteria::Pluck
  extend ActiveSupport::Concern

  included { criteria_option :missing_attributes, :merge_with =>
               NoBrainer::Criteria::Pluck.method(:merge_missing_attributes) }

  def pluck(*attrs)
    _missing_attributes_criteria(:pluck, attrs)
  end

  def without(*attrs)
    _missing_attributes_criteria(:without, attrs)
  end

  def lazy_fetch(*attrs)
    _missing_attributes_criteria(:lazy_fetch, attrs)
  end

  def without_plucking
    chain(:missing_attributes => :remove)
  end

  def self.merge_missing_attributes(a, b)
    return nil if b.nil? || b == :remove

    a = a ? a.dup : {}
    b.each do |type, attrs|
      old_attrs = a[type] || {}.with_indifferent_access
      new_attrs = old_attrs.deep_merge(attrs)
      a[type] = new_attrs
    end
    a
  end

  private

  def _missing_attributes_criteria(type, args)
    raise ArgumentError if args.size.zero?
    args = [Hash[args.flatten.map { |k| [k, true] }]] unless args.size == 1 && args.first.is_a?(Hash)
    chain(:missing_attributes => {type => args.first})
  end

  def effective_missing_attributes
    return nil if @options[:missing_attributes].nil?
    @effective_missing_attributes ||= begin
      # pluck gets priority
      missing_attributes = Hash[@options[:missing_attributes].map do |type, attrs|
        attrs = attrs.select { |k,v| v } # TODO recursive
        attrs.empty? ? nil : [type, attrs]
      end.compact]

      if missing_attributes[:pluck]
        { :pluck => missing_attributes[:pluck] }
      else
        attrs = [missing_attributes[:without], missing_attributes[:lazy_fetch]].compact.reduce(&:merge)
        { :without => attrs } if attrs.present?
      end
    end
  end

  def _instantiate_model(attrs, options={})
    return super if @options[:missing_attributes].nil?
    super(attrs, options.merge(:missing_attributes => effective_missing_attributes,
                               :lazy_fetch => @options[:missing_attributes][:lazy_fetch]))
  end

  def compile_rql_pass2
    rql = super
    if effective_missing_attributes
      type, attrs = effective_missing_attributes.first
      rql = rql.__send__(type, model.with_fields_aliased(attrs))
    end
    rql
  end
end
