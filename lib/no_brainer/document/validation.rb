module NoBrainer::Document::Validation
  extend NoBrainer::Autoload
  extend ActiveSupport::Concern
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  autoload_and_include :Uniqueness, :NotNull

  included do
    # We don't want before_validation returning false to halt the chain.
    define_callbacks :validation, :skip_after_callbacks_if_terminated => true,
                     :scope => [:kind, :name], :terminator => proc { false }
  end

  def valid?(context=nil, options={})
    context ||= new_record? ? :create : :update

   # XXX Monkey Patching, because we need to have control on errors.clear
    current_context, self.validation_context = validation_context, context
    errors.clear unless options[:clear_errors] == false
    run_validations!
  ensure
    self.validation_context = current_context
  end

  SHORTHANDS = { :format => :format, :length => :length, :required => :not_null,
                 :uniq => :uniqueness, :unique => :uniqueness, :in => :inclusion }

  module ClassMethods
    def _field(attr, options={})
      super

      SHORTHANDS.each { |k,v| validates(attr, v => options[k]) if options.has_key?(k) }
      validates(attr, options[:validates]) if options[:validates]
    end
  end
end
