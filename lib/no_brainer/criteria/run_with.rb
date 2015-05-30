module NoBrainer::Criteria::RunWith
  extend ActiveSupport::Concern

  included { criteria_option :run_with, :merge_with => :merge_hash }

  def run_with(options={})
    chain(:run_with => options.symbolize_keys)
  end

  private

  def run(&block)
    return finalized_criteria.__send__(:run, &block) unless finalized?
    block ||= proc { to_rql }
    run_options = finalized_criteria.options[:run_with] || {}
    NoBrainer.run(run_options.merge(:criteria => self), &block)
  end
end
