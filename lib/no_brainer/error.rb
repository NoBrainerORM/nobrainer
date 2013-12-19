module NoBrainer::Error
  class Connection       < StandardError; end
  class DocumentNotFound < StandardError; end
  class DocumentInvalid  < StandardError; end
  class DocumentNotSaved < StandardError; end
  class ChildrenExist    < StandardError; end
end
