class NoBrainer::Geo::LineString < Struct.new(:points)
  include NoBrainer::Geo::Base

  def initialize(*points)
    self.points = points.map { |p| NoBrainer::Geo::Point.nobrainer_cast_user_to_model(p) }
  end

  def to_rql
    RethinkDB::RQL.new.line(points.map(&:to_rql))
  end
end
