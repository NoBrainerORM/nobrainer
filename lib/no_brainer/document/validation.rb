module NoBrainer::Document::Validation
  extend ActiveSupport::Concern
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  def save(options={})
    options = options.reverse_merge(:validate => true)

    if options[:validate]
      valid? ? super : false
    else
      super
    end
  end

  # TODO Test that thing
  def valid?(context=nil)
    super(context || (new_record? ? :create : :update))
  end

  [:save, :update_attributes].each do |method|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{method}!(*args)
        #{method}(*args) or raise NoBrainer::Error::DocumentInvalid, errors
      end
    RUBY
  end

  # Validate the document for uniqueness violations.
  #
  # @example Validate the document.
  #   validate_each(person, :title, "Sir")
  #
  # @param [ Document ] document The document to validate.
  # @param [ Symbol ] attribute The field to validate on.
  # @param [ Object ] value The value of the field.
  #
  # @return [ Boolean ] true if the attribute is unique.
  class UniquenessValidator < ActiveModel::EachValidator
    def validate_each(document, attribute, value)
      self.class.validate_each(document, attribute, value)
    end

    def self.validate_each(document, attribute, value)
      is_unique = document.class.where(attribute => value).count == 0
      unless is_unique
        document.errors.add(attribute, 'is already taken')
      end
      is_unique
    end
  end
end
