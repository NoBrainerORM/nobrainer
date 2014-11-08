module NoBrainer::Criteria::AfterFind
  extend ActiveSupport::Concern

  included { criteria_option :after_find, :merge_with => :append_array }

  def after_find(b=nil, &block)
    chain(:after_find => [b, block].compact)
  end

  def _instantiate_doc(attrs)
    super.tap do |doc|
      @options[:after_find].to_a.each { |block| block.call(doc) }
      doc.run_callbacks(:find) if doc.is_a?(NoBrainer::Document)
    end
  end
end
