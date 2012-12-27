module NoBrainer::Selection::Core
  extend ActiveSupport::Concern

  included do
    attr_accessor :query, :context
    delegate :inspect, :to => :query
  end

  def initialize(query_or_selection, context={})
    # We are saving klass as a context
    # so that the table_on_demand middleware can do its job
    # TODO FIXME Sadly it gets funny with associations
    if query_or_selection.is_a? NoBrainer::Selection
      selection = query_or_selection
      self.query = selection.query
      self.context = selection.context
    else
      query = query_or_selection
      self.query = query
      self.context = context
    end
  end

  def klass
    context[:klass]
  end

  def chain(query)
    NoBrainer::Selection.new(query, context)
  end

  def run
    NoBrainer.run { self }
  end
end
