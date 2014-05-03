module NoBrainer::Document::Core
  extend ActiveSupport::Concern

  singleton_class.class_eval do
    attr_accessor :_all

    def all
      Rails.application.eager_load! if defined?(Rails.application.eager_load!)
      @_all
    end
  end
  self._all = []

  # TODO This assume the primary key is id.
  # RethinkDB can have a custom primary key. careful.
  include ActiveModel::Conversion

  included do
    # TODO test these includes
    extend ActiveModel::Naming
    extend ActiveModel::Translation

    NoBrainer::Document::Core._all << self
  end
end
