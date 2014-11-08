module NoBrainer::Criteria::Extend
  extend ActiveSupport::Concern

  included { attr_accessor :extend_modules }

  def extend(*modules, &block)
    options = modules.extract_options!
    modules << Module.new(&block) if block

    return super(*modules) if options[:original_behavior]

    chain do |criteria|
      criteria.extend_modules ||= []
      criteria.extend_modules += [modules]
    end
  end

  def merge!(criteria, options={})
    super

    if criteria.extend_modules.present?
      self.extend_modules = self.extend_modules.to_a + criteria.extend_modules
    end

    if self.extend_modules.present?
      self.extend_modules.each { |modules| extend(*modules, :original_behavior => true) }
    end

    self
  end
end
