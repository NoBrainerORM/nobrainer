module NoBrainer::Criteria::Update
  extend ActiveSupport::Concern

  def update_all(*a, &b)
    prepare_args_for_update!(a)
    run(without_ordering.to_rql.update(*a, &b))
  end

  def replace_all(*a, &b)
    prepare_args_for_update!(a)
    run(without_ordering.to_rql.replace(*a, &b))
  end

  private

  def prepare_args_for_update!(a)
    a[0] = klass.persistable_attributes(a[0]) if !a.empty? && a.first.is_a?(Hash)
  end
end
