module CallbacksHelper
  def record_callbacks(klass)
    klass.class_eval do
      class_attribute :callbacks, :callbacks_of
      self.callbacks = []
      self.callbacks_of = {}

      [:before, :after].each do |when_|
        [:validation, :create, :update, :save, :destroy].each do |action|
          cb = :"#{when_}_#{action}"
          __send__(cb) do
            self.class.callbacks << cb
            (self.class.callbacks_of[id] ||= []) << cb
          end
        end
      end
    end
  end
end
