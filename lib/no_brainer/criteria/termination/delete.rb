module NoBrainer::Criteria::Termination::Delete
  extend ActiveSupport::Concern

  def delete_all
    run(to_rql.delete)['deleted']
  end

  def destroy_all
    to_a.each { |doc| doc.destroy }
  end
end
