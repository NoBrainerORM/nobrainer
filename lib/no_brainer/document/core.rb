module NoBrainer::Document::Core
  extend ActiveSupport::Concern

  singleton_class.class_eval do
    attr_accessor :_all, :_all_nobrainer

    def all
      Rails.application.eager_load! if defined?(Rails.application.eager_load!)
      @_all
    end
  end
  self._all = []
  self._all_nobrainer = []

  include ActiveModel::Conversion

  def to_key
    [pk_value]
  end

  included do
    # TODO test these includes
    extend ActiveModel::Naming
    extend ActiveModel::Translation

    list_name = self.name =~ /^NoBrainer::/ ? :_all_nobrainer : :_all
    NoBrainer::Document::Core.__send__(list_name) << self
  end
end
