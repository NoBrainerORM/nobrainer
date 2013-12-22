module NoBrainer::Criteria::Termination::Delete
  extend ActiveSupport::Concern

  def delete_all
    run(to_rql.delete)['deleted']
  end

  def destroy_all
    each { |doc| doc.destroy }
  end
end
