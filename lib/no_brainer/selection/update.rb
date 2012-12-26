module NoBrainer::Selection::Update
  def update(attrs={}, &block)
    block = proc { attrs } unless block_given?
    chain(query.update(&block)).run
  end
end
