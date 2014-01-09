module NoBrainer::Criteria::Chainable::AfterFind
  extend ActiveSupport::Concern

  included { attr_accessor :_after_find }

  def after_find(b=nil, &block)
    chain { |criteria| criteria._after_find = [b || block] }
  end

  def merge!(criteria, options={})
    super
    if criteria._after_find.present?
      self._after_find = (self._after_find || []) + criteria._after_find
    end
    self
  end

  def instantiate_doc(attrs)
    super.tap do |doc|
      self._after_find.to_a.each { |block| block.call(doc) }
      doc.run_callbacks(:find) if doc.is_a?(NoBrainer::Document)
    end
  end
end
