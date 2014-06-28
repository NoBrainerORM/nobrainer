class String
  module NoBrainerExtentions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when String then value
      when Symbol then value.to_s
      else raise InvalidType
      end
    end
  end
  extend NoBrainerExtentions
end
