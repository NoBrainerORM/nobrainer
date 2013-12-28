module NoBrainer::Fork
  def self.hook
    Kernel.module_eval do
      alias_method :fork_without_nobrainer, :fork

      def fork(&block)
        NoBrainer.disconnect
        fork_without_nobrainer(&block)
      end

      module_function :fork
    end
  end
end
