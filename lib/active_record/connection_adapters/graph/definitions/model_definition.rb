module ActiveRecord
  module ConnectionAdapters
    module Graph
      module Definitions
        class ModelDefinition
          attr_accessor :columns, :class_name
          def initialize(model_name, base)
            @model_name = model_name.to_s
            @columns = []
            @primary_key = nil
            @base = base
          end

          def column(column_name, column_type, options={})
             @columns << {:name => column_name.to_s, :type => @base.type_to_sql(column_type).to_sym.to_s}.inspect
          end

          def timestamps(*args)
            options = args.extract_options!
            column :created_at, :datetime, options
            column :updated_at, :datetime, options
          end

          def primary_key(name)
            column(name, :primary_key)
            @primary_key = name.to_s
          end

          def to_hash
            return_hash = {}
            return_hash['model'] = @model_name
            return_hash['columns'] = @columns
            return_hash['primary_key'] = @primary_key
            return_hash['class_name'] = @class_name
        
            return_hash
          end

          %w( string text integer float decimal datetime timestamp time date binary boolean ).each do |column_type|
            class_eval <<-EOV, __FILE__, __LINE__ + 1
              def #{column_type}(*args)                                               # def string(*args)
                options = args.extract_options!                                       #   options = args.extract_options!
                column_names = args                                                   #   column_names = args
                                                                                      #
                column_names.each { |name| column(name, '#{column_type}', options) }  #   column_names.each { |name| column(name, 'string', options) }
              end                                                                     # end
            EOV
          end

        end
      end
    end
  end
end
