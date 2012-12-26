module NoBrainer::QueryRunner
  extend NoBrainer::Loader

  # Middlewares. Order matters.
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
