module NoBrainer::Criteria::Termination::Delete
  def delete
    NoBrainer.run { to_rql.delete }
  end

  def destroy
    each { |doc| doc.destroy }
  end
end
