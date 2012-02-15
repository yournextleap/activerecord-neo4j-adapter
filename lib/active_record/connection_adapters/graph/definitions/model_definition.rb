module ActiveRecord
  module ConnectionAdapters
    module Graph
      module Definitions
        class ModelDefinition
          attr_accessor :columns
          def initialize(model_name)
            @model_name = model_name.to_s
            @columns = []
          end

          def column(column_name, column_type, options={})
             @columns << {:name => column_name.to_s, :type => column_type.to_s}.inspect
          end

          def timestamps(*args)
            options = args.extract_options!
            column :created_at, :datetime, options
            column :updated_at, :datetime, options
          end

          def to_hash
            return_hash = {}
            return_hash['model'] = @model_name
            return_hash['columns'] = @columns
        
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
