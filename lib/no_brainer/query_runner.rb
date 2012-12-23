module NoBrainer::QueryRunner
  extend ActiveSupport::Autoload

  def self.use(middleware)
    autoload middleware
    extend const_get middleware
  end

  def self.run(options={}, &block)
    super :query => yield, :options => options
  end

  use :Connection
  use :DatabaseOnDemand
  use :TableOnDemand
  use :WriteError
end
