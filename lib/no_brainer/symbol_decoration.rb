module NoBrainer::SymbolDecoration
  NON_CHAINABLE_OPERATORS = %w(in eq gt ge gte lt le lte defined undefined near intersects include).map(&:to_sym)
  CHAINABLE_OPERATORS = %w(not any all).map(&:to_sym)
  OPERATORS = CHAINABLE_OPERATORS + NON_CHAINABLE_OPERATORS

  def self.hook
    require 'symbol_decoration'
    Symbol::Decoration.register(*NON_CHAINABLE_OPERATORS)
    Symbol::Decoration.register(*CHAINABLE_OPERATORS, :chainable => true)
  end
end
