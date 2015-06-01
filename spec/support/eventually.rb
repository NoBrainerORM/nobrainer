module EventuallyHelper
  extend self

  def eventually(options = {})
    timeout = options[:timeout] || 3
    interval = options[:interval] || 0.1
    time_limit = Time.now + timeout
    loop do
      begin
        yield
      rescue Exception => error
      end
      return if error.nil?
      raise error if Time.now >= time_limit
      sleep interval.to_f
    end
  end
end

RSpec.configure do |config|
  config.include EventuallyHelper
end
