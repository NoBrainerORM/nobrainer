module NoBrainer::Criteria::Nearest
  extend ActiveSupport::Concern

  included { criteria_option :nearest_point, :nearest_options, :merge_with => :set_scalar }

  include ::RethinkDB::Shortcuts
  def nearest(point, options)
    @options[:ordering_mode] = :disabled
    chain(:nearest_point => point, :nearest_options => options)
  end

  def compile_rql_pass1
    rql = super
    rql = rql.get_nearest(r.point(@options[:nearest_point].x, @options[:nearest_point].y), @options[:nearest_options]).map {|res| res['doc']} if @options[:nearest_point] && @options[:nearest_options]
    rql
  end

end