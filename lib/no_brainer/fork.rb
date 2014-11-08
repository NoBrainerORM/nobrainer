module NoBrainer::Fork
  def self.hook
    Kernel.module_eval do
      alias_method :fork_without_nobrainer, :fork

      def fork(&block)
        # Not so safe to disconnect in the child (c.f. driver's code)
        NoBrainer.disconnect
        fork_without_nobrainer(&block)
      end

      module_function :fork
    end
  end
end
