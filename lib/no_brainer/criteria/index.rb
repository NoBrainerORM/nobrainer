module NoBrainer::Criteria::Index
  extend ActiveSupport::Concern

  included { criteria_option :use_index, :merge_with => :set_scalar }

  def with_index(index_name=true)
    chain(:use_index => index_name)
  end

  def without_index
    with_index(false)
  end

  def without_index?
    finalized_criteria.options[:use_index] == false
  end

  def used_index
    # Only one of them will be active.
    where_index_name || order_by_index_name
  end

  def compile_rql_pass2
    super.tap do
      # The implicit ordering on the indexed pk does not count.
      if @options[:use_index] && (!used_index || order_by_index_name.to_s == model.pk_name.to_s)
        raise NoBrainer::Error::CannotUseIndex.new(@options[:use_index])
      end
    end
  end
end
