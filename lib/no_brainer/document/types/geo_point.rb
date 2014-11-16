module NoBrainer::Geo
  class Point < Struct.new(:longitude, :latitude)

    def to_rql
      RethinkDB::RQL.new.point(self.longitude, self.latitude)
    end

    class << self
      def nobrainer_cast_user_to_model(value)
        case value
        when NoBrainer::Geo::Point then value
        when Hash then
            longitude = value[:longitude] ||= value[:long] ||= value['longitude'] ||= value['long']
            latitude = value[:latitude] ||= value[:lat] ||= value['latitude'] ||= value['latitude']
            raise NoBrainer::Error::InvalidType.new('longitude out of range') if longitude < -180 || longitude > 180
            raise NoBrainer::Error::InvalidType.new('latitude out of range') if latitude < -90 || latitude > 90
            raise 'You must supply :longitude and :latitude!' unless latitude && longitude
            new(longitude, latitude)
        else raise NoBrainer::Error::InvalidType
        end
      end

      def nobrainer_cast_model_to_db(value)
        RethinkDB::RQL.new.point(value.longitude, value.latitude)
      end

      # This class method translates a value from the database to the proper type.
      # It is used when reading from the database.
      def nobrainer_cast_db_to_model(value)
        NoBrainer::Geo::Point.new(value['coordinates'][0], value['coordinates'][1])
      end
    end
  end
end