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
  class LostLock                < RuntimeError; end
  class LockInvalidOp           < RuntimeError; end
  class LockUnavailable         < RuntimeError; end
  class InvalidPolymorphicType  < RuntimeError; end

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
    attr_accessor :model, :attr_name, :value, :type, :error
    def initialize(options={})
      update(options)
    end

    def update(options={})
      options.assert_valid_keys(:model, :attr_name, :type, :value, :error)
      options.each { |k,v| instance_variable_set("@#{k}", v) }
    end

    def human_type_name
      type.to_s.underscore.humanize.downcase
    end

    def error
      # dup because errors.add eventually .delete() on our option.
      @error.nil? ? (type && { :type => human_type_name }) : @error.dup
    end

    def message
      return super unless model && attr_name && error
      value = self.value
      mock = model.allocate
      mock.singleton_class.send(:define_method, :read_attribute_for_validation) { |_| value }
      mock.errors.add(attr_name, :invalid_type, **error)
      mock.errors.full_messages.first
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
