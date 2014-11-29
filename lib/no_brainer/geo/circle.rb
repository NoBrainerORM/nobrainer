class NoBrainer::Geo::Circle < Struct.new(:center, :radius, :options)
  include NoBrainer::Geo::Base

  def initialize(*args)
    options = args.extract_options!
    options = NoBrainer::Geo::Base.normalize_geo_options(options)

    raise NoBrainer::Error::InvalidType if args.size > 2
    center = args[0] || options.delete(:center)
    radius = args[1] || options.delete(:radius)

    center = NoBrainer::Geo::Point.nobrainer_cast_user_to_model(center)
    radius = Float.nobrainer_cast_user_to_model(radius)

    self.center = center
    self.radius = radius
    self.options = options
  end

  def to_rql
    RethinkDB::RQL.new.circle(center.to_rql, radius, options)
  end

  # No DB serialization, can't store circles.
end
