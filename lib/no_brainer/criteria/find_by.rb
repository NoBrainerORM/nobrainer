module NoBrainer::Criteria::FindBy
  extend ActiveSupport::Concern

  def find_by?(*args, &block)
    where(*args, &block).first
  end

  def find_by(*args, &block)
    find_by?(*args, &block).tap { |doc| raise NoBrainer::Error::DocumentNotFound unless doc }
  end
end
