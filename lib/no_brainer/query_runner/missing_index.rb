class NoBrainer::QueryRunner::MissingIndex < NoBrainer::QueryRunner::Middleware
  def call(env)
    @runner.call(env)
  rescue RuntimeError => e
    if match_data = /^Index `(.+)` was not found on table `(.+)\.(.+)`\.$/.match(e.message)
      _, index_name, db_name, table_name = *match_data

      model = NoBrainer::Document.all.select { |m| m.table_name == table_name }.first
      index = model.indexes.values.select { |i| i.aliased_name == index_name.to_sym }.first if model
      index_name = index.name if index

      if model.try(:pk_name).try(:to_s) == index_name.to_s
        err_msg  = "Please update the primary key `#{index_name}` in the table `#{db_name}.#{table_name}`."
      else
        err_msg  = "Please run `NoBrainer.sync_indexes' or `rake nobrainer:sync_indexes' to create the index `#{index_name}`"
        err_msg += " in the table `#{db_name}.#{table_name}`."
        err_msg += " Read http://nobrainer.io/docs/indexes for more information."
      end

      raise NoBrainer::Error::MissingIndex.new(err_msg)
    end
    raise
  end
end
