module NoBrainer::Criteria::Index
  extend ActiveSupport::Concern

  included { attr_accessor :with_index_name }

  def with_index(index_name=true)
    chain { |criteria| criteria.with_index_name = index_name }
  end

  def without_index
    with_index(false)
  end

  def without_index?
    finalized_criteria.with_index_name == false
  end

  def used_index
    # only one of them will be active.
    where_index_name || order_by_index_name
  end

  def merge!(criteria, options={})
    super
    self.with_index_name = criteria.with_index_name unless criteria.with_index_name.nil?
    self
  end

  def compile_rql_pass2
    super.tap do
      if with_index_name && (!used_index || order_by_index_name.to_s == klass.pk_name.to_s)
        # The implicit ordering on the indexed pk does not count.
        raise NoBrainer::Error::CannotUseIndex.new(with_index_name)
      end
    end
  end
end
