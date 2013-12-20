class NoBrainer::DecoratedSymbol < Struct.new(:symbol, :modifier)
  MODIFIERS = { :ne => :ne, :not => :ne, :in => :in, :eq => :eq,
                :gt => :gt, :ge => :ge, :gte => :ge,
                :lt => :lt, :le => :le, :lte => :le}

  def self.hook
    Symbol.class_eval do
      MODIFIERS.each do |modifier_name, modifier|
        define_method modifier_name do
          NoBrainer::DecoratedSymbol.new(self, modifier)
        end
      end
    end
  end
end
