module NoBrainer::Document::Validation
  extend ActiveSupport::Concern
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  included do
    # We don't want before_validation returning false to halt the chain.
    define_callbacks :validation, :skip_after_callbacks_if_terminated => true,
                     :scope => [:kind, :name], :terminator => proc { false }
  end

  def valid?(context=nil, options={})
    context ||= new_record? ? :create : :update

  # copy/pasted, because we need to have control on errors.clear
    current_context, self.validation_context = validation_context, context
    errors.clear unless options[:clear_errors] == false
    run_validations!
  ensure
    self.validation_context = current_context
  end

  module ClassMethods
    def _field(attr, options={})
      super
      validates(attr, :format => { :with => options[:format] }) if options.has_key?(:format)
      validates(attr, :presence => true) if options.has_key?(:required) && options[:required]==:presence
      validates(attr, :definition => true) if options.has_key?(:required) && options[:required]==true
      validates(attr, :uniqueness => options[:unique]) if options.has_key?(:unique)
      validates(attr, :uniqueness => options[:uniq]) if options.has_key?(:uniq)
      validates(attr, :inclusion => {:in => options[:in]}) if options.has_key?(:in)
      validates(attr, options[:validates]) if options[:validates]
    end
  end
end
