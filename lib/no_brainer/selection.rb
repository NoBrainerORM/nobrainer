class NoBrainer::Selection
  attr_accessor :selection

  def initialize(selection)
    self.selection = selection
  end

  def count
    NoBrainer.run { selection.count }
  end

  [:filter, :order_by, :skip, :limit].each do |method|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{method}(*args, &block)
        self.class.new selection.#{method}(*args, &block)
      end
    RUBY
  end

  alias_method :where, :filter

  def inspect
    selection.inspect.gsub(/^db\(:default_db\)./, '')
  end
end
