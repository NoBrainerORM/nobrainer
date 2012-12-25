module NoBrainer::Document::Validation
  extend ActiveSupport::Concern
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  def save(options={})
    options.reverse_merge!(:validate => true)

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

  [:save, :update_attributes, :update_attribute].each do |method|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{method}!(*args)
        #{method}(*args) or raise NoBrainer::Error::Validations, errors
      end
    RUBY
  end
end
