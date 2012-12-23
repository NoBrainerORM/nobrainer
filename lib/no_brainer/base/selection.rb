module NoBrainer::Base::Selection
  extend ActiveSupport::Concern

  def selector
    @selector ||= self.class.selector_for(id)
  end

  module ClassMethods
    def all
      NoBrainer::Selection.new(table, self)
    end

    delegate :count, :where, :first, :last, :to => :all

    def selector_for(id)
      NoBrainer::Selection.new(table.get(id), self)
    end

    def _find(id)
      # TODO Pass primary key if not default
      attrs = selector_for(id).run
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
