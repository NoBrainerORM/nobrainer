module NoBrainer::QueryRunner
  extend ActiveSupport::Autoload

  def self.use(middleware)
    autoload middleware
    extend const_get middleware
  end

  use :Driver
  use :DatabaseOnDemand
  use :TableOnDemand
  use :WriteError
  use :Connection
  use :Selection

  def self.run(options={}, &block)
    super :query => yield, :options => options
  end
end
