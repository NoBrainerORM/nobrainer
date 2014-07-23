require 'time'

class Time
  module NoBrainerExtentions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when Time then time = value
      when String
        value = value.strip.sub(/Z$/, '+00:00')
        # Using DateTime to preserve the timezone offset
        dt = DateTime.parse(value) rescue (raise InvalidType)
        time = Time.new(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.zone)
        raise InvalidType unless time.iso8601 == value
      else raise InvalidType
      end

      nobrainer_timezoned(NoBrainer::Config.user_timezone, time)
    end

    def nobrainer_cast_db_to_model(value)
      return value unless value.is_a?(Time)
      nobrainer_timezoned(NoBrainer::Config.user_timezone, value)
    end

    def nobrainer_cast_model_to_db(value)
      return value unless value.is_a?(Time)
      nobrainer_timezoned(NoBrainer::Config.db_timezone, value)
    end

    def nobrainer_timezoned(tz, value)
      case tz
      when :local     then value.getlocal
      when :utc       then value.getutc
      when :unchanged then value
      end
    end
  end
  extend NoBrainerExtentions
end
