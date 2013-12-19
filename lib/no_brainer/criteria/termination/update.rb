module NoBrainer::Criteria::Termination::Update
  def update_all(attrs={}, &block)
    block = proc { attrs } unless block_given?
    run(to_rql.update(&block))
  end
end
