module CallbacksHelper
  def record_callbacks(model)
    model.class_eval do
      class_attribute :callbacks, :callbacks_of
      self.callbacks = []
      self.callbacks_of = {}

      [:before, :after].each do |when_|
        [:initialize, :find, :validation, :create, :update, :save, :destroy].each do |action|
          next if action == :find && when_ == :before
          cb = :"#{when_}_#{action}"
          __send__(cb) do
            self.class.callbacks << cb
            (self.class.callbacks_of[pk_value] ||= []) << cb rescue nil
          end
        end
      end
    end
  end
end
