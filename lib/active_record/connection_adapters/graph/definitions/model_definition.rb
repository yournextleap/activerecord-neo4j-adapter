class ActiveRecord::ConnectionAdapters::Graph::Definitions::ModelDefinition
  def initialize(model_name)
    @model_name = model_name.to_s
    @columns = {}
  end

  def column(column_name, column_type, options={})
    @columns[column_name.to_s] = column_type.to_s
  end

  def timestamps(*args)
    options = args.extract_options!
    column :created_at, :datetime, options
    column :updated_at, :datetime, options
  end

  def to_hash
    return_hash = {}
    return_hash['model'] = @model_name
    return_hash.merge! @columns

    return_hash
  end
end
