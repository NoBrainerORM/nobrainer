# frozen_string_literal: true

module NoBrainer
  #
  # Parent class of all migration scripts.
  # This class is used by the NoBrainer::Migrator class.
  #
  class Migration
    class NoImplementedError < StandardError; end

    def migrate!
      up
    rescue StandardError
      raise unless respond_to?(:down)

      begin
        down
        raise
      rescue StandardError
        raise
      end
    end

    def rollback!
      down if respond_to?(:down)
    rescue StandardError
      raise
    end

    def up
      raise NoImplementedError
    end
  end
end
