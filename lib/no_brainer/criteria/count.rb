module NoBrainer::Criteria::Count
  extend ActiveSupport::Concern

  def count
    run { without_ordering.without_plucking.to_rql.count }
  end

  def empty?
    count == 0
  end

  def any?
    if block_given?
      to_a.any? { |*args| yield(*args) }
    else
      !empty?
    end
  end
end
