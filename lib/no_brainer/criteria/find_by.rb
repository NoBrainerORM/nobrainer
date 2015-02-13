module NoBrainer::Criteria::FindBy
  extend ActiveSupport::Concern

  def find_by(*block)
    where(*block).first
  end

  def find_by!(*block)
    find_by(*block).tap { |doc| raise NoBrainer::Error::DocumentNotFound unless doc }
  end
end
