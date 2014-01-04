module NoBrainer::Error
  class Connection          < StandardError; end
  class DocumentNotFound    < StandardError; end
  class DocumentInvalid     < StandardError; end
  class DocumentNotSaved    < StandardError; end
  class ChildrenExist       < StandardError; end
  class CannotUseIndex      < StandardError; end
  class MissingIndex        < StandardError; end
  class InvalidType         < StandardError; end
  class AssociationNotSaved < StandardError; end
end
