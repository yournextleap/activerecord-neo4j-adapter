require 'neography/node'
require 'active_record/connection_adapters/graph/definitions/model_definition'

module ActiveRecord
  module ConnectionAdapters
    module Neo4j
      module Sql
        module DatabaseStatements
          def tables(name=nil, database=nil)
            table_names = neo_server.find_node_index(indices[:model], 'type', 'model').collect{|node| node['data']['model']} rescue nil
            table_names || []
          end # tables

          def create_table(model_name, options={})
            
            raise ArgumentError.new("Model #{model_name} already exists!") if table_exists?(model_name)

            model_definition = ActiveRecord::ConnectionAdapters::Graph::Definitions::ModelDefinition.new model_name

            yield model_definition if block_given?

            model_node = Neography::Node.create neo_server, model_definition.to_hash
            
            neo_server.add_node_to_index indices[:model], 'type', 'model', model_node
            neo_server.add_node_to_index indices[:model], 'model', model_name, model_node
          end # create_table

          def drop_table(model_name, options={})
            # Get the model node
            model_node = get_model_node model_name

            # Remove model node from indices
            neo_server.remove_node_from_index indices[:model], 'type', 'model', model_node
            neo_server.remove_node_from_index indices[:model], 'model', model_name, model_node

            # Delete the node
            model_node.del
          end # drop_table

          def add_index(model_name, column_name, options={})
            # Get model node
            model_node = get_model_node model_name

            # Check if index exists on the model
            raise ArgumentError.new("Index for #{column_name.inspect} exists on model #{model_name}")\
             if model_node.indices.present? and (model_node.indices & column_index_name_for(column_name, options)).present?

            # Add new indices
            model_indices = model_node.respond_to?(:indices) ? model_node.indices : []
            model_indices += column_index_name_for(column_name, options)

            # Update model with new indices
            neo_server.set_node_properties model_node, {'indices' => model_indices}
          end # add_index

          def columns(model_name, log_msg=nil)
            
          end

          protected
          def get_model_node(model_name)
            model_node_attributes = neo_server.find_node_index indices[:model], 'model', model_name
            raise ArgumentError.new("Model #{model_name} does not exist!") if not model_node_attributes.present?
            model_node_id = model_node_attributes.first['self'].split('/').last.to_i
            model_node = Neography::Node.load(model_node_id)
          end

          def column_index_name_for(column_name, options = {})
            column_names = Array.wrap(column_name)
            column_names.collect{|column_name| index_hash_for(column_name, options).inspect}
          end

          def index_hash_for(column_name, options)
            index_hash = {}
            index_hash[:column] = column_name
            index_hash[:name] = options[:name] if options[:name].present?
            index_hash[:unique] = options[:unique].present?
            index_hash
          end
        end # DatabaseStatements
      end # Sql
    end # Neo4j
  end # ConnectionAdapters
end # ActiveRecord

