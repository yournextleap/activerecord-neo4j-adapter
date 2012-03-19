module Neo4j
  class Result
    include Enumerable

    attr_accessor :columns, :data
    def initialize(model_columns, model_data)
      @columns = model_columns
      @data = model_data
    end

    def each(options = {})
      case options[:as]
      when :hash
        result = []
        @data.each do |row|
          result << @columns.zip(row).map{|column, value| denormalize_column_values(column, value)}\
                    .inject({}){|hash, injected| hash.merge!(injected)}
        end
        result
      else
        @data.each do |row|
          yield row
        end
      end
    end

    def denormalize_column_values(column, value)
      return {column => (value == "null" ? nil : value)} if (column != 'properties')

      # Since Neo4j 1.7M01, map() returns a hash
      # So no need to gsub on a string output obtained from map() any more
      value
    end

  end # Result
end # Neo4j
