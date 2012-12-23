module NoBrainer::Base::Selection
  extend ActiveSupport::Concern

  def selector
    @selector ||= table.get(id)
  end

  module ClassMethods
    def all
      NoBrainer::Selection.new(table)
    end

    delegate :count, :where, :to => :all

    def _find(id)
      # TODO Pass primary key if not default
      attrs = NoBrainer.run { table.get(id) }
      unless attrs
        raise NoBrainer::Error::NotFound, "id #{id} not found"
      end

      yield attrs
    end

    def find(id)
      _find(id) do |attrs|
        self.new.instance_eval do
          # TODO Does this block belongs in the Field module ?
          # TODO Should we reject undeclared fields ?
          @attributes = attrs
          @new_record = false
          self
        end
      end
    end
  end
end
