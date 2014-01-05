module NoBrainer::Document::Core
  extend ActiveSupport::Concern

  singleton_class.send(:attr_accessor, :all)
  self.all = []

  # TODO This assume the primary key is id.
  # RethinkDB can have a custom primary key. careful.
  include ActiveModel::Conversion

  included do
    # TODO test these includes
    extend ActiveModel::Naming
    extend ActiveModel::Translation

    NoBrainer::Document::Core.all << self
  end

  def initialize(attrs={}, options={}); end
end
