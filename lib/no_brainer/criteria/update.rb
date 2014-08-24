module NoBrainer::Criteria::Update
  extend ActiveSupport::Concern

  def update_all(*a, &b)
    attrs_lookup_field_alias!(a)
    run(without_ordering.to_rql.update(*a, &b))
  end

  def replace_all(*a, &b)
    attrs_lookup_field_alias!(a)
    run(without_ordering.to_rql.replace(*a, &b))
  end

  private

  def attrs_lookup_field_alias!(a)
    a[0] = klass.persistable_attributes(a[0]) if !a.empty? && a.first.is_a?(Hash)
  end
end
