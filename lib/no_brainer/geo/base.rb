module NoBrainer::Geo::Base
  extend ActiveSupport::Concern

  def self.normalize_geo_options(options)
    options = options.symbolize_keys

    geo_system  = options.delete(:geo_system) || NoBrainer::Config.geo_options[:geo_system]
    unit        = options.delete(:unit) || NoBrainer::Config.geo_options[:unit]

    options[:unit] = unit if unit && unit.to_s != 'm'
    options[:geo_system] = geo_system if geo_system && geo_system.to_s != 'WGS84'
    options[:max_dist] = options.delete(:max_distance) if options[:max_distance]

    options
  end
end
