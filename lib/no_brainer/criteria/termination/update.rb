module NoBrainer::Criteria::Termination::Update
  def update(attrs={}, &block)
    block = proc { attrs } unless block_given?
    NoBrainer.run { to_rql.update(&block) }
  end
end
