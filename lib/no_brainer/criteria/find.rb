module NoBrainer::Criteria::Find
  extend ActiveSupport::Concern

  def find_by(*args, &block)
    raise "find_by() has unclear semantics. Please use where().first instead"
  end
  alias_method :find_by!, :find_by
  alias_method :find_by?, :find_by

  def find?(pk)
    without_ordering.where(model.pk_name => pk).first
  end

  def find(pk)
    find?(pk).tap { |doc| raise_not_found(pk) unless doc }
  end
  alias_method :find!, :find

  private

  def raise_not_found(pk)
    raise NoBrainer::Error::DocumentNotFound, "#{model} :#{model.pk_name}=>#{pk.inspect} not found"
  end
end
