module NoBrainer::QueryRunner
  extend ActiveSupport::Autoload

  def self.use(middleware)
    autoload middleware
    extend const_get middleware
  end

  use :Connection
  use :DatabaseOnDemand
  use :TableOnDemand

  def self.run(options={}, &block)
    super :query => yield, :options => options
  end
end
