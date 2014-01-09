module NoBrainer::Error
  class Connection          < RuntimeError; end
  class DocumentNotFound    < RuntimeError; end
  class DocumentInvalid     < RuntimeError; end
  class DocumentNotSaved    < RuntimeError; end
  class ChildrenExist       < RuntimeError; end
  class CannotUseIndex      < RuntimeError; end
  class MissingIndex        < RuntimeError; end
  class InvalidType         < RuntimeError; end
  class AssociationNotSaved < RuntimeError; end

  class InvalidType < RuntimeError
    attr_accessor :attr_name, :value, :type
    def initialize(options={})
      @attr_name = options[:attr_name]
      @value     = options[:value]
      @type      = options[:type]
    end

    def human_type_name
      type.to_s.underscore.humanize.downcase
    end

    def message
      "#{attr_name} should be used with a #{human_type_name}. Got `#{value}`"
    end
  end
end
