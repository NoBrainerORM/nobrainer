class NoBrainer::Config

  attr_accessor :logger, :log_level, :log_prefix

  def initialize

    @logger = defined?(Rails) ? Rails.logger : Logger.new(STDERR).tap { |l| l.level = Logger::WARN }
    @log_level = Logger::INFO
    @log_prefix = '[NoBrainer]'
  end

end