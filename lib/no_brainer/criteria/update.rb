module NoBrainer::Criteria::Update
  extend ActiveSupport::Concern

  def update_all(*args, &block)
    run(to_rql.update(*args, &block))
  end

  def replace_all(*args, &block)
    run(to_rql.replace(*args, &block))
  end
end
