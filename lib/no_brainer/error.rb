module NoBrainer::Error
  class Connection < StandardError; end
  class NotFound < StandardError; end
  class Validations < StandardError; end
end
