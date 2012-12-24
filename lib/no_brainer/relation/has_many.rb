class NoBrainer::Relation::HasMany < Struct.new(:klass, :children, :options)
  def hook
  end
end
