module NoBrainer::Criteria::Termination::Delete
  def delete_all
    run(to_rql.delete)
  end

  def destroy_all
    each { |doc| doc.destroy }
  end
end
