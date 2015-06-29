module NoBrainer::Document::Cache
  extend NoBrainer::Autoload
  extend ActiveSupport::Concern

  # Print out the cache key.
  # Will append different values on the plural model name if
  # new_record?   - will append /new
  # updated_at    - will append /id-updated_at.to_s(:number)
  # No timestamps - will append /id

  # This is usually called inside a cache() block on the view
  #<% cache(@profile) do %>

  # @example Returns the cache key
  # @return [String] the string with or without updated_at

  def cache_key
    case
    when new_record?
      "#{model_key}/new"
    when updated = self.try(:updated_at)
      timestamp = updated.utc.to_s(:nsec)
      "#{model_key}/#{pk_value}-#{timestamp}"
    else
      "#{model_key}/#{pk_value}"
    end
  end

  private
  def model_key
    @model_cache_key ||= "#{self.class.model_name.cache_key}"
  end

end
