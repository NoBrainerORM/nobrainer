module NoBrainer::Criteria::Update
  extend ActiveSupport::Concern

  def update_all(*a, &b)
    perform_update(:update, a, b)
  end

  def replace_all(*a, &b)
    perform_update(:replace, a, b)
  end

  private

  def perform_update(type, args, block)
    args[0] = model.persistable_attributes(args[0]) if !args.empty? && args.first.is_a?(Hash)
    # can't use without_distinct when passed a block as the operation may be
    # performed many times, which might not be idempotent.
    clause = block ? self : without_distinct
    run { clause.without_plucking.to_rql.__send__(type, *args, &block) }
  end
end
