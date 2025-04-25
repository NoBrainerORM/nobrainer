# frozen_string_literal: true

require 'spec_helper'

describe NoBrainer::Deprecations do # rubocop:disable RSpec/SpecFilePathFormat
  before { allow(NoBrainer.logger).to receive(:warn).and_call_original }

  %w[1.8.7 1.9.0 2.1.0].each do |ruby_version|
    describe "#check#{ruby_version}" do
      before do
        stub_const('RUBY_VERSION', ruby_version)
        described_class.check
      end

      it 'does warn' do
        expect(NoBrainer.logger)
          .to have_received(:warn).with(
            /Using ruby #{ruby_version} with the nobrainer gem is deprecated./
          )
      end
    end
  end

  %w[2.2.0 2.3.0 2.6.0 2.7.2 3.0.7 3.1.0 3.4.2].each do |ruby_version|
    describe "#check#{ruby_version}" do
      before do
        stub_const('RUBY_VERSION', ruby_version)
        described_class.check
      end

      it 'does not warn' do
        expect(NoBrainer.logger)
          .not_to have_received(:warn)
      end
    end
  end
end
