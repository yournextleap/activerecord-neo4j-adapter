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

      value.gsub(/(\{|\})/,'')\
            .split(', ')\
            .map{|pair| {pair.split('=')[0] => pair.split('=')[1]}}\
            .inject({}){|hash, injected| hash.merge!(injected)}
    end

  end # Result
end # Neo4j