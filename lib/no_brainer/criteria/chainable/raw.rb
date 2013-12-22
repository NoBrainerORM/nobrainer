module NoBrainer::Criteria::Chainable::Raw
  extend ActiveSupport::Concern

  included { attr_accessor :_raw }

  def raw
    chain { |criteria| criteria._raw = true }
  end

  def raw?
    !!_raw
  end

  def merge!(criteria)
    super
    self._raw = criteria._raw unless criteria._raw.nil?
    self
  end

  private

  def instantiate_doc(attrs)
    raw? ? attrs : klass.new_from_db(attrs)
  end
end
