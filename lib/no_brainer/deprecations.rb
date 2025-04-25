# frozen_string_literal: true

module NoBrainer
  module Deprecations
    MIN_SUPPORTED_RUBY_VERSION = '2.2.0'

    def self.check
      return if RUBY_VERSION >= MIN_SUPPORTED_RUBY_VERSION

      # Ruby 2.2 doesn't support heredoc like:
      # <<~MSG.split.join(' ')
      #  Using ruby #{RUBY_VERSION} with the nobrainer gem is deprecated.
      #  Ruby #{MIN_SUPPORTED_RUBY_VERSION} or higher will be required to use
      #  this gem in future versions.
      # MSG
      NoBrainer.logger.warn(
        "Using ruby #{RUBY_VERSION} with the nobrainer gem is deprecated. " \
        "Ruby #{MIN_SUPPORTED_RUBY_VERSION} or higher will be required to " \
        'use this gem future versions.'
      )
    end
  end
end
