class NoBrainer::GeoPoint < Struct.new(:x, :y)

  def to_rql
    RethinkDB::RQL.new.point(self.x, self.y)
  end

  class << self
    def nobrainer_cast_user_to_model(value)
      case value
      when NoBrainer::GeoPoint then value
      when Hash then
        x = value[:x] ? value[:x] : value['x']
        y = value[:y] ? value[:y] : value['y']
        raise "You must supply :x and :y!" unless x && y
        new(x, y)
      else raise NoBrainer::Error::InvalidType
      end
    end

    def nobrainer_cast_model_to_db(value)
      RethinkDB::RQL.new.point(value.x, value.y)
    end

    # This class method translates a value from the database to the proper type.
    # It is used when reading from the database.
    def nobrainer_cast_db_to_model(value)
      NoBrainer::GeoPoint.new(value['coordinates'][0], value['coordinates'][1])
    end
  end

end