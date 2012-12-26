module NoBrainer::Selection::Core
  extend ActiveSupport::Concern

  included do
    attr_accessor :query, :klass
    delegate :inspect, :to => :query
  end

  def initialize(query_or_selection, klass=nil)
    # We are saving klass as a context
    # so that the table_on_demand middleware can do its job
    # TODO FIXME Sadly it gets funny with associations
    if query_or_selection.is_a? NoBrainer::Selection
      selection = query_or_selection
      self.query = selection.query
      self.klass = selection.klass
    else
      query = query_or_selection
      self.query = query
      self.klass = klass
    end
  end

  def chain(query)
    NoBrainer::Selection.new(query, klass)
  end

  def run
    NoBrainer.run { self }
  end
end
