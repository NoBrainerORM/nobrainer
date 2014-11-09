# We namespace our fake Boolean class to avoid polluting the global namespace
class NoBrainer::Boolean
  def initialize; raise; end
  def self.inspect; 'Boolean'; end
  def self.to_s; inspect; end
  def self.name; inspect; end

  module NoBrainerExtentions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when TrueClass  then true
      when FalseClass then false
      when String, Integer
        value = value.to_s.strip.downcase
        return true  if value.in? %w(true yes t 1)
        return false if value.in? %w(false no f 0)
        raise InvalidType
      else raise InvalidType
      end
    end
  end
  extend NoBrainerExtentions
end
