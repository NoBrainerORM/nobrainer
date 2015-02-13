module NoBrainer::Criteria::Find
  extend ActiveSupport::Concern

  def find_by?(*args, &block)
    where(*args, &block).first
  end

  def find_by(*args, &block)
    find_by?(*args, &block).tap { |doc| raise_not_found(args) unless doc }
  end
  alias_method :find_by!, :find_by

  def find?(pk)
    without_ordering.find_by?(model.pk_name => pk)
  end

  def find(pk)
    without_ordering.find_by(model.pk_name => pk)
  end
  alias_method :find!, :find

  private

  def raise_not_found(args)
    raise NoBrainer::Error::DocumentNotFound, "#{model} #{args.inspect.gsub(/\[{(.*)}\]/, '\1')} not found"
  end
end
