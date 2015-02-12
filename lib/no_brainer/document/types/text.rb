class NoBrainer::Text
  def initialize; raise; end
  def self.inspect; 'Text'; end
  def self.to_s; inspect; end
  def self.name; inspect; end

  module NoBrainerExtensions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when String then value
      else raise InvalidType
      end
    end
  end
  extend NoBrainerExtensions
end
