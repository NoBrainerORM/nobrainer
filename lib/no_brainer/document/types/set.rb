class Set
  module NoBrainerExtentions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when Set   then value
      when Array then Set.new(value)
      else raise InvalidType
      end
    end

    def nobrainer_cast_db_to_model(value)
      value.is_a?(Array) ? Set.new(value) : value
    end

    def nobrainer_cast_model_to_db(value)
      value.is_a?(Set) ? value.to_a : value
    end
  end

  extend NoBrainerExtentions
end
