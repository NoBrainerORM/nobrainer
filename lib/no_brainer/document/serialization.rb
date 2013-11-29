module NoBrainer::Document::Serialization
  extend ActiveSupport::Concern

  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  included { self.include_root_in_json = false }

  # XXX This was a giant copy paste from lib/active_model/serialization.rb
  # It has been refactored to smell a bit better
  def serializable_hash(options = nil)
    options ||= {}

    hash = attributes_and_methods_hash(
      serialization_class.filter_attribute_names(
        self.class.fields.keys.sort, options),
      options[:methods])

    serializable_add_includes(options) do |association, records, opts|
      hash[association] = module_klass.associated_hash_value(records, opts)
    end

    hash
  end

  private
  def serialization_class
    # This is admittedly a little smelly, but it prevents us having to break
    # out a new module just for two utility functions (or including those
    # utility functions directly when included in a document
    NoBrainer::Document::Serialization
  end

  def attributes_and_methods_hash(attributes, methods)
    serialized_attributes(attributes).merge(serialized_methods(methods))
  end

  def serialized_attributes(attributes)
    Hash[
      attributes.map {|name| [name, read_attribute_for_serialization(name)]}
    ]
  end

  def serialized_methods(methods)
    Hash[
      Array.wrap(methods).select {|name| respond_to?(name)}.map {|name| [name, send(name)]}
    ]
  end

  def self.associated_hash_value(records, opts)
    # This is a utility function to grab the serializable hash of the records
    # passed in
    records.is_a?(Enumerable) ?
      records.map {|record| record.serializable_hash(opts)} :
      records.serializable_hash(opts)
  end

  def self.filter_attribute_names(attribute_names, options)
    # This is a utility function to get us a list of attribute names, possibly
    # filtered by :only and :except
    if only = options[:only]
      return attribute_names & Array.wrap(only).map(&:to_s)
    elsif except = options[:except]
      return attribute_names - Array.wrap(except).map(&:to_s)
    end
    attribute_names
  end
end
