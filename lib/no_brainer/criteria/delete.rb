module NoBrainer::Criteria::Delete
  extend ActiveSupport::Concern

  def delete_all
    run { without_distinct.without_ordering.without_plucking.to_rql.delete }
  end

  def destroy_all
    to_a.each(&:destroy)
  end
end
