module NoBrainer::Criteria::Termination::First
  extend ActiveSupport::Concern

  def first
    get_one(self)
  end

  def last
    get_one(self.reverse_order)
  end

  private

  def get_one(criteria)
    instantiate_doc(criteria.limit(1).run.first)
  end
end
