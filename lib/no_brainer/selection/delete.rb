module NoBrainer::Selection::Delete
  def delete
    chain(query.delete).run
  end

  def destroy
    each { |doc| doc.destroy }
  end
end
