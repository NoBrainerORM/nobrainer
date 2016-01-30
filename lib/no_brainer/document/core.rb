module NoBrainer::Document::Core
  extend ActiveSupport::Concern

  singleton_class.class_eval { attr_accessor :_all }
  self._all = []

  included do
    # TODO test these includes
    extend ActiveModel::Naming
    extend ActiveModel::Translation

    unless name =~ /^NoBrainer::/
      if NoBrainer::Document::Core._all.map(&:name).include?(name)
        raise "Fatal: The model `#{name}' is already registered and partially loaded.\n" +
              "This may happen when an exception occured while loading the model definitions\n" +
              "(e.g. calling a missing class method on another model, having circular dependencies).\n" +
              "In this situation, ActiveSupport autoloader may retry loading the model.\n" +
              "Try moving all class methods declaration at the top of the model."
      end
      NoBrainer::Document::Core._all << self
    end
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

  def self.reflect_on_association(association)
    puts "TEST"
  end
end
