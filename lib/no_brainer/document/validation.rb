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

  class UniquenessValidator < ActiveModel::EachValidator
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
    def validate_each(document, attribute, value)
      criteria = document.root_class.unscoped.where(attribute => value)
      criteria = apply_scopes(criteria, document)
      criteria = exclude_document(criteria, document) if document.persisted?
      is_unique = criteria.count == 0
      document.errors.add(attribute, 'is already taken') unless is_unique
      is_unique
    end

    def apply_scopes(criteria, document)
      criteria.where([*options[:scope]].map { |k| {k => document.read_attribute(k)} })
    end

    def exclude_document(criteria, document)
      criteria.where(:id.ne => document.id)
    end
  end
end
