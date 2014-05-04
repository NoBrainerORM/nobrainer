module NoBrainer::Criteria::Delete
  extend ActiveSupport::Concern

  def delete_all
    run(without_ordering.to_rql.delete)
  end

  def destroy_all
    without_ordering.to_a.each { |doc| doc.destroy }
  end
end
