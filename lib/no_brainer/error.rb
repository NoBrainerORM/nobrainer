module NoBrainer::Error
  class Connection       < StandardError; end
  class DocumentNotFound < StandardError; end
  class DocumentInvalid  < StandardError; end
  class DocumentNotSaved < StandardError; end
  class ChildrenExist    < StandardError; end
  class CannotUseIndex   < StandardError; end
  class InvalidType      < StandardError; end
  class ParentNotSaved   < StandardError; end
end
