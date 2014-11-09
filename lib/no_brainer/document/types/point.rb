class NoBrainer::Point < Struct.new(:x, :y)

    class << self
      include ::RethinkDB::Shortcuts
      def nobrainer_cast_user_to_model(value)
        case value
          when NoBrainer::Point then value
          when Hash then new(value[:x] || value['x'], value[:y] || value['y'])
          else raise NoBrainer::Error::InvalidType
        end
      end

      def nobrainer_cast_model_to_db(value)
        r.point(value.x, value.y)
      end

      # This class method translates a value from the database to the proper type.
      # It is used when reading from the database.
      def nobrainer_cast_db_to_model(value)
        NoBrainer::Point.new(value['coordinates'][0], value['coordinates'][1])
      end
    end

end