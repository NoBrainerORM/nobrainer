module NoBrainer::Criteria::Raw
  extend ActiveSupport::Concern

  included { criteria_option :raw, :merge_with => :set_scalar }

  def raw(value = true)
    chain(:raw => value)
  end

  def raw?
    !!finalized_criteria.options[:raw]
  end

  private

  def instantiate_doc(attrs)
    finalized_criteria._instantiate_doc(attrs)
  end

  def _instantiate_doc(attrs)
    raw? ? attrs : _instantiate_model(attrs)
  end

  def _instantiate_model(attrs, options={})
    model.new_from_db(attrs, options)
  end
end
