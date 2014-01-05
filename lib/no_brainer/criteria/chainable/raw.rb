module NoBrainer::Criteria::Chainable::Raw
  extend ActiveSupport::Concern

  included { attr_accessor :_raw, :__after_instantiate }

  def raw
    chain { |criteria| criteria._raw = true }
  end

  def _after_instantiate(block)
    # Just some helper for the has_many association to set the inverses on the
    # related belongs_to. A bit hackish.
    chain { |criteria| criteria.__after_instantiate = block }
  end

  def merge!(criteria, options={})
    super
    self._raw = criteria._raw unless criteria._raw.nil?
    self.__after_instantiate ||= criteria.__after_instantiate
    self
  end

  private

  def raw?
    !!_raw
  end

  def instantiate_doc(attrs)
    (raw? ? attrs : klass.new_from_db(attrs))
      .tap { |doc| __after_instantiate.call(doc) if __after_instantiate }
  end
end
