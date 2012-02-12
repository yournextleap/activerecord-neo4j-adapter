require 'neography/node'
require 'active_record/connection_adapters/graph/definitions/model_definition'

module ActiveRecord
  module ConnectionAdapters
    module Neo4j
      module Sql
        module DatabaseStatements
          def tables(name=nil, database=nil)
            table_names = neo_server.find_node_index indices[:model], 'type', 'model'
            table_names || []
          end # tables

          def create_table(model_name, options={})
            model_definition = ActiveRecord::ConnectionAdapters::Graph::Definitions::ModelDefinition.new model_name

            yield model_definition if block_given?

            model_node = Neography::Node.create neo_server, model_definition.to_hash
            
            neo_server.add_node_to_index indices[:model], 'type', 'model', model_node
            neo_server.add_node_to_index indices[:model], 'model', model_name, model_node
          end
        end # DatabaseStatements
      end # Sql
    end # Neo4j
  end # ConnectionAdapters
end # ActiveRecord

