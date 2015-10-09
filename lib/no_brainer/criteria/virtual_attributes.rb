module NoBrainer::Criteria::VirtualAttributes
  extend ActiveSupport::Concern

  def compile_rql_pass2
    rql = super

    if model.virtual_fields
      rql = rql.map do |_doc|
        model.virtual_fields.reduce(_doc) do |doc, field|
          field_rql = model.fields[field][:virtual].call(doc, RethinkDB::RQL.new)
          if field_rql.nil?
            doc
          else
            unless field_rql.is_a?(RethinkDB::RQL)
              raise "The virtual attribute `#{model}.#{field}' should return a RQL expression"
            end
            doc.merge(field => field_rql)
          end
        end
      end
    end

    rql
  end
end
