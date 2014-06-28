class Symbol
  module NoBrainerExtentions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when Symbol then value
      when String
        value = value.strip
        raise InvalidType if value.empty?
        value.to_sym
      else raise InvalidType
      end
    end

    def nobrainer_cast_db_to_model(value)
      value.to_sym rescue (value.to_s.to_sym rescue value)
    end
  end
  extend NoBrainerExtentions
end
