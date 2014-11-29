require 'no_brainer/document/types/float'

class NoBrainer::Geo::Point < Struct.new(:longitude, :latitude)
  include NoBrainer::Geo::Base

  def initialize(*args)
    if args.size == 2
      longitude, latitude = args
    elsif args.size == 1 && args.first.is_a?(self.class)
      longitude, latitude = args.first.longitude, args.first.latitude
    elsif args.size == 1 && args.first.is_a?(Hash)
      opt = args.first.symbolize_keys
      longitude, latitude = opt[:longitude] || opt[:long], opt[:latitude] || opt[:lat]
    else
      raise NoBrainer::Error::InvalidType
    end

    longitude = Float.nobrainer_cast_user_to_model(longitude)
    latitude  = Float.nobrainer_cast_user_to_model(latitude)

    raise NoBrainer::Error::InvalidType unless (-180..180).include?(longitude)
    raise NoBrainer::Error::InvalidType unless (-90..90).include?(latitude)

    self.longitude = longitude
    self.latitude = latitude
  end

  def to_rql
    RethinkDB::RQL.new.point(longitude, latitude)
  end

  def to_s
    [longitude, latitude].inspect
  end
  alias_method :inspect, :to_s

  def self.nobrainer_cast_user_to_model(value)
    value.is_a?(Array) ? new(*value) : new(value)
  end

  def self.nobrainer_cast_db_to_model(value)
    return value unless value.is_a?(Hash) && value['coordinates'].is_a?(Array) && value['coordinates'].size == 2
    new(value['coordinates'][0], value['coordinates'][1])
  end

  def self.nobrainer_cast_model_to_db(value)
    value.is_a?(self) ? value.to_rql : value
  end
end
