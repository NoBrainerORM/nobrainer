class Date
  module NoBrainerExtentions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when Date then value
      when String
        value = value.strip
        date = Date.parse(value) rescue (raise InvalidType)
        raise InvalidType unless date.iso8601 == value
        date
      else raise InvalidType
      end
    end

    def nobrainer_cast_db_to_model(value)
      value.is_a?(Time) ? value.to_date : value
    end

    def nobrainer_cast_model_to_db(value)
      value.is_a?(Date) ? Time.utc(value.year, value.month, value.day) : value
    end
  end
  extend NoBrainerExtentions
end
