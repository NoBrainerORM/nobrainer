module NoBrainer::Document::Serialization
  extend ActiveSupport::Concern

  include ActiveModel::Serialization
  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  included { self.include_root_in_json = false }

  # XXX This is a giant copy paste from lib/active_model/serialization.rb
  # The diff is:
  # - attribute_names = attributes.keys.sort
  # + attribute_names = self.class.fields.keys.sort
  # That's all.
  def serializable_hash(options = nil)
    options ||= {}

    attribute_names = self.class.fields.keys.sort
    if only = options[:only]
      attribute_names &= Array.wrap(only).map(&:to_s)
    elsif except = options[:except]
      attribute_names -= Array.wrap(except).map(&:to_s)
    end

    hash = {}
    attribute_names.each { |n| hash[n] = read_attribute_for_serialization(n) }

    method_names = Array.wrap(options[:methods]).select { |n| respond_to?(n) }
    method_names.each { |n| hash[n] = send(n) }

    serializable_add_includes(options) do |association, records, opts|
      hash[association] = if records.is_a?(Enumerable)
        records.map { |a| a.serializable_hash(opts) }
      else
        records.serializable_hash(opts)
      end
    end

    hash
  end
end
