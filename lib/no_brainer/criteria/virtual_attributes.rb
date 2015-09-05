module NoBrainer::Criteria::VirtualAttributes
  extend ActiveSupport::Concern

  def compile_rql_pass2
    rql = super

    if model.virtual_fields
      rql = rql.map do |_doc|
        model.virtual_fields.reduce(_doc) do |doc, field|
          field_rql = model.fields[field][:virtual].call(doc, RethinkDB::RQL.new)
          field_rql.nil? ? doc : doc.merge(field => field_rql)
        end
      end
    end

    rql
  end
end
