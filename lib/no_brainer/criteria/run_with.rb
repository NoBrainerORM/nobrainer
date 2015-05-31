module NoBrainer::Criteria::RunWith
  extend ActiveSupport::Concern

  included do
    criteria_option :original_nobrainer_run_options, :merge_with => :set_scalar
    criteria_option :run_with, :merge_with => :merge_hash
  end

  def run_with(options={})
    chain(:run_with => options.symbolize_keys)
  end

  private

  def run(&block)
    return finalized_criteria.__send__(:run, &block) unless finalized?
    ensure_same_run_option_context!

    block ||= proc { to_rql }
    run_options = @options[:run_with] || {}
    NoBrainer.run(run_options.merge(:criteria => self), &block)
  end

  def ensure_same_run_option_context!
    orig_run_options = @options[:original_nobrainer_run_options]
    unless orig_run_options.nil? || orig_run_options == NoBrainer.current_run_options
      raise "The current criteria cannot be executed as it was constructed in a different `run_with()' context\n" +
            "Note: you may use `run_with()' directly in your query (e.g. Model.run_with(...).first)."
    end
  end
end
