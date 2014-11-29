module NoBrainer::Geo
  extend NoBrainer::Autoload
  autoload :Base, :Point, :Circle, :LineString, :Polygon
end
