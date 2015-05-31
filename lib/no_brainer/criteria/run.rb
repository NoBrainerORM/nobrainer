module NoBrainer::Criteria::Run
  extend ActiveSupport::Concern

  included do
    criteria_option :initial_run_options, :merge_with => :set_scalar
    criteria_option :run_with, :merge_with => :merge_hash
  end

  private

  def run(&block)
    return finalized_criteria.__send__(:run, &block) unless finalized?
    ensure_same_run_option_context!

    block ||= proc { to_rql }
    NoBrainer.run(:criteria => self, &block)
  end

  def ensure_same_run_option_context!
    return if @options[:initial_run_options].nil?
    return if @options[:initial_run_options] == NoBrainer.current_run_options

    raise "The current criteria cannot be executed as it was constructed in a different `run_with()' context\n" +
          "Note: you may use `run_with()' directly in your query (e.g. Model.run_with(...).first)."
  end
end
