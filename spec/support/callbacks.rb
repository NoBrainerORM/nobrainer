module CallbacksHelper
  def record_callbacks(klass)
    klass.class_eval do
      class_attribute :callbacks
      self.callbacks = {}

      after_create  { (self.class.callbacks[id] ||= []).unshift :create  }
      after_update  { (self.class.callbacks[id] ||= []).unshift :update  }
      after_save    { (self.class.callbacks[id] ||= []).unshift :save    }
    end
  end
end
