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

  include ActiveModel::Conversion

  def to_key
    [pk_value]
  end

  included do
    # TODO test these includes
    extend ActiveModel::Naming
    extend ActiveModel::Translation

    NoBrainer::Document::Core._all << self unless self.name =~ /^NoBrainer::/
  end
end
