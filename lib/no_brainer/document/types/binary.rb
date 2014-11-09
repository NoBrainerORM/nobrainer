class NoBrainer::Binary
  def initialize; raise; end
  def self.inspect; 'Binary'; end
  def self.to_s; inspect; end
  def self.name; inspect; end

  module NoBrainerExtentions
    InvalidType = NoBrainer::Error::InvalidType

    def nobrainer_cast_user_to_model(value)
      case value
      when String then RethinkDB::Binary.new(value)
      else raise InvalidType
      end
    end

    def nobrainer_cast_db_to_model(value)
      value.is_a?(String) ? RethinkDB::Binary.new(value) : value
    end
  end
  extend NoBrainerExtentions
end
