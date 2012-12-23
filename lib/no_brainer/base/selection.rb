module NoBrainer::Base::Selection
  extend ActiveSupport::Concern

  def selector
    @selector ||= table.get(id)
  end

  module ClassMethods
    def all
      NoBrainer::Selection.new(table, self)
    end

    delegate :count, :where, :first, :last, :to => :all

    def _find(id)
      # TODO Pass primary key if not default
      attrs = NoBrainer.run { table.get(id) }
      unless attrs
        raise NoBrainer::Error::NotFound, "id #{id} not found"
      end

      yield attrs
    end

    def find(id)
      _find(id) { |attrs| from_attributes(attrs) }
    end
  end
end
