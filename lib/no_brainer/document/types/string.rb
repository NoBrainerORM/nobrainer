class String
  module NoBrainerExtentions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when String then value
      when Symbol then value.to_s
      else raise InvalidType
      end.tap do |str|
        max_length = NoBrainer::Config.max_string_length
        raise InvalidType.new(:error => { :message => :too_long, :count => max_length }) if str.size > max_length
      end
    end
  end
  extend NoBrainerExtentions
end
