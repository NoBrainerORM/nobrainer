# frozen_string_literal: true

require 'rails/generators/nobrainer/namespace_fix'
require 'rails/generators/named_base'

module NoBrainer
  module Generators
    #
    # Generates a migration script prefixed with the date and time of
    # its creation.
    #
    class MigrationGenerator < Rails::Generators::NamedBase
      extend NoBrainer::Generators::NamespaceFix
      source_root File.expand_path('../templates', __dir__)

      desc 'Generates a new migration script in ./db/migrate/'

      check_class_collision

      def create_model_file
        template 'migration.rb', File.join('db', 'migrate', timestamped_filename)
      end

      hook_for :test_framework

      def timestamped_filename
        "#{Time.current.strftime('%Y%m%d%H%M%S')}_#{file_name}.rb"
      end
    end
  end
end
