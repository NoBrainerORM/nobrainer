module NoBrainer::Criteria::Limit
  extend ActiveSupport::Concern

  included { criteria_option :skip, :limit, :merge_with => :set_scalar }

  def limit(value)
    chain(:limit => value)
  end

  def skip(value)
    chain(:skip => value)
  end
  alias_method :offset, :skip

  private

  def compile_rql_pass2
    rql = super
    rql = rql.skip(@options[:skip]) if @options[:skip]
    rql = rql.limit(@options[:limit]) if @options[:limit]
    rql
  end
end
