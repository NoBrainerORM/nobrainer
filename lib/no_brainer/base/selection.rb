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
      # TODO Pass primary key if not default
      NoBrainer::Selection.new(table.get(id), self)
    end

    # XXX this doesn't have the same semantics as
    # other ORMs. the equivalent is find!.
    def find(id)
      new_from_db(selector_for(id).run)
    end

    def find!(id)
      find(id).tap do |model|
        unless model
          raise NoBrainer::Error::NotFound, "#{self.class} id #{id} not found"
        end
      end
    end
  end
end
