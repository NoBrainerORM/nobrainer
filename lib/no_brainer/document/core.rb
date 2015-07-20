module NoBrainer::Document::Core
  extend ActiveSupport::Concern

  singleton_class.class_eval { attr_accessor :_all }
  self._all = []

  included do
    # TODO test these includes
    extend ActiveModel::Naming
    extend ActiveModel::Translation

    NoBrainer::Document::Core._all << self unless name =~ /^NoBrainer::/
  end

  def self.all(options={})
    (options[:types] || [:user]).map do |type|
      case type
      when :user
        Rails.application.eager_load! if defined?(Rails.application.eager_load!)
        _all
      when :nobrainer
        [NoBrainer::Document::Index::MetaStore, NoBrainer::Lock]
      when :system
        NoBrainer::System.constants
          .map { |c| NoBrainer::System.const_get(c) }
          .select { |m| m < NoBrainer::Document }
      end
    end.reduce([], &:+)
  end
end
