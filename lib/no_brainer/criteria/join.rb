module NoBrainer::Criteria::Join
  extend ActiveSupport::Concern

  included { criteria_option :join_on, :merge_with => :set_scalar }

  def join(association_name)
    chain(:join_on => association_name.to_sym)
  end

  def merge!(criteria, options={})
    if @options[:join_on] && criteria.options[:join_on]
      raise "You can only do a single join in your query at the moment"
    end
    super
  end

  private

  def _instantiate_model(attrs, options={})
    return super if !@options[:join_on] || raw?

    bt = belongs_to_association

    left = super(attrs['left'], options)
    right = bt.target_model.new_from_db(attrs['right'], {})

    left.associations[bt].preload([right])

    left
  end

  def belongs_to_association
    @belongs_to_association ||= begin
      association_name = @options[:join_on]
      association = model.association_metadata[association_name]
      unless association.is_a?(NoBrainer::Document::Association::BelongsTo::Metadata)
        raise "`#{association_name}' must be a belongs_to association on `#{model}'"
      end
      association
    end
  end

  def compile_rql_pass2
    return super unless @options[:join_on]

    bt = belongs_to_association
    super.eq_join(bt.foreign_key, bt.target_model.rql_table, :index => bt.primary_key)
  end
end
