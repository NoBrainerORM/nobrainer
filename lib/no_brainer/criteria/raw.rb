module NoBrainer::Criteria::Raw
  extend ActiveSupport::Concern

  included { attr_accessor :_raw }

  def raw
    chain { |criteria| criteria._raw = true }
  end

  def merge!(criteria, options={})
    super
    self._raw = criteria._raw unless criteria._raw.nil?
    self
  end

  private

  def instantiate_doc(attrs)
    raw? ? attrs : instantiate_model(attrs)
  end

  def instantiate_model(attrs, options={})
    klass.new_from_db(attrs, options)
  end

  def raw?
    !!_raw
  end
end
