module NoBrainer::Error
  class Connection  < StandardError; end
  class NotFound    < StandardError; end
  class Validations < StandardError; end
  class Write       < StandardError; end
end
