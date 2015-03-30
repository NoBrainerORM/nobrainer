module NoBrainer::Criteria::Find
  extend ActiveSupport::Concern

  def find_by?(*args, &block)
    where(*args, &block).first
  end

  def find_by(*args, &block)
    find_by?(*args, &block).tap { |doc| raise_not_found(args) unless doc }
  end
  alias_method :find_by!, :find_by

  def find?(*pks)
    expects_array = pks.first.kind_of?(Array)
    return pks.first if expects_array && pks.first.empty?
    
    pks = pks.flatten.compact.uniq
    
    case pks.size
    when 0
      nil
    when 1
      doc = without_ordering.find_by?(model.pk_name => pks.first)
      expects_array ? [ doc ] : doc
    else
      find_some(pks)
    end
  end

  def find(*pks)
    expects_array = pks.first.kind_of?(Array)
    return pks.first if expects_array && pks.first.empty?
    
    pks = pks.flatten.compact.uniq
    
    case pks.size
    when 0
      raise_not_found(pks)
    when 1
      doc = without_ordering.find_by(model.pk_name => pks.first)
      expects_array ? [ doc ] : doc
    else
      docs = find_some(pks)
      if docs.count == pks.size
       docs
      else
       missing_pks = pks - docs.map(&:pk_value)
       raise_not_found([model.pk_name => missing_pks.join(', ')])
      end
    end
  end
  alias_method :find!, :find

  private

  def raise_not_found(args)
    raise NoBrainer::Error::DocumentNotFound, "#{model} #{args.inspect.gsub(/\[{(.*)}\]/, '\1')} not found"
  end
  
  def find_some(pks)
    without_ordering.where({:or => pks.map {|pk| {model.pk_name => pk} } })
  end
end
