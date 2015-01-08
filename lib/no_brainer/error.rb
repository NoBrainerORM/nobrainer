module NoBrainer::Error
  class Connection              < RuntimeError; end
  class DocumentNotFound        < RuntimeError; end
  class DocumentNotPersisted    < RuntimeError; end
  class ChildrenExist           < RuntimeError; end
  class CannotUseIndex          < RuntimeError; end
  class MissingIndex            < RuntimeError; end
  class AssociationNotPersisted < RuntimeError; end
  class ReadonlyField           < RuntimeError; end
  class MissingAttribute        < RuntimeError; end
  class UnknownAttribute        < RuntimeError; end
  class AtomicBlock             < RuntimeError; end

  class DocumentInvalid < RuntimeError
    attr_accessor :instance
    def initialize(instance)
      @instance = instance
    end

    def message
      "#{instance} is invalid: #{instance.errors.full_messages.join(", ")}"
    end
  end

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
      if attr_name && type && value
        "#{attr_name} should be used with a #{human_type_name}. Got `#{value}` (#{value.class})"
      else
        super
      end
    end
  end

  class CannotUseIndex < RuntimeError
    attr_accessor :index_name
    def initialize(index_name)
      @index_name = index_name
    end

    def message
      if index_name == true
        "Cannot use any indexes"
      else
        "Cannot use index #{index_name}"
      end
    end
  end
end
