module NoBrainer::Criteria::Extend
  extend ActiveSupport::Concern

  included { criteria_option :extend, :merge_with => :append_array }

  def extend(*modules, &block)
    options = modules.extract_options!
    modules << Module.new(&block) if block

    return super(*modules) if options[:original_behavior]
    chain(:extend => [modules])
  end

  def merge!(criteria, options={})
    super.tap do
      @options[:extend].to_a.each { |modules| extend(*modules, :original_behavior => true) }
    end
  end
end
