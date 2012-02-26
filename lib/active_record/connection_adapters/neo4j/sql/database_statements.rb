require 'neography/node'
require 'active_record/connection_adapters/graph/definitions/model_definition'
require 'neo4j/result'

module ActiveRecord
  module ConnectionAdapters
    module Neo4j
      module Sql
        module DatabaseStatements
          require 'active_record/connection_adapters/neo4j/accessor'
          include ActiveRecord::ConnectionAdapters::Neo4j::Accessor

          def tables(name=nil, database=nil)
            table_names = neo_server.find_node_index(indices[:model], 'type', 'model').collect{|node| node['data']['model']} rescue nil
            table_names || []
          end # tables

          def create_table(model_name, options={})
            
            raise ArgumentError.new("Model #{model_name} already exists!") if table_exists?(model_name)

            model_definition = ActiveRecord::ConnectionAdapters::Graph::Definitions::ModelDefinition.new model_name, self
            model_definition.primary_key(options[:primary_key] || Base.get_primary_key(model_name.to_s.singularize)) unless options[:id] == false

            model_definition.class_name = options[:class_name] if options[:class_name]

            yield model_definition if block_given?

            model_node = Neography::Node.create neo_server, model_definition.to_hash
            
            neo_server.add_node_to_index indices[:model], 'type', 'model', model_node
            neo_server.add_node_to_index indices[:model], 'model', model_name, model_node
          end # create_table

          def primary_key(model_name)
            model_node = get_model_node model_name
            model_node.primary_key
          end # primary_key

          def drop_table(model_name, options={})
            # Delete all model instances
            delete_all_instances_of model_name

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

          def add_column(model_name, column_name, type, options = {})
            model_node = get_model_node model_name
            model_definition = ActiveRecord::ConnectionAdapters::Graph::Definitions::ModelDefinition.initialize_from_node(model_node, self)
            model_definition.column column_name, type
            neo_server.set_node_properties model_node, {'columns' => model_definition.columns}
          end # add_column

          def remove_column(model_name, *column_names)
            model_node = get_model_node model_name
            model_definition = ActiveRecord::ConnectionAdapters::Graph::Definitions::ModelDefinition.initialize_from_node(model_node, self)

            model_definition.columns.reject!{|column| column_names.map{|column_name| column_name.to_s}.include?(eval(column)[:name])}
            neo_server.set_node_properties model_node, {'columns' => model_definition.columns}

            #execute_remove_properties model_name, column_names
          end

          def columns(model_name, log_msg=nil)
            model_node = get_model_node model_name
            model_node.columns.collect{|column| Column.new eval(column)[:name], nil, eval(column)[:type]}
          end

          def select_rows(arel_response, name=nil)
            result = send "execute_#{arel_response.type}", arel_response.params, name
            ::Neo4j::Result.new(result['columns'], result['data']).to_a
          end

          protected

          def insert_sql(arel_response, name = nil, pk = nil, id_value = nil, sequence_name = nil)
            send "execute_#{arel_response.type}", arel_response.params, name
            #id_value
          end

          def update_sql(arel_response, name=nil)
            send "execute_#{arel_response.type}", arel_response.params, name
          end

          def delete_sql(arel_response, name=nil)
            send "execute_#{arel_response.type}", arel_response.params, name
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

          private
          def select(arel_response, name=nil)
            result = send "execute_#{arel_response.type}", arel_response.params, name
            ::Neo4j::Result.new(result['columns'], result['data']).each(:as => :hash)
          end # select

          def delete_all_instances_of model_name
            model_node_id = get_model_node_id model_name

            script = [
                      "g",
                      "v(#{model_node_id})",
                      "out('instances')",
                      "each{g.removeVertex(it)}"
                    ].join('.')

            neo_server.execute_script script
          end
        end # DatabaseStatements
      end # Sql
    end # Neo4j
  end # ConnectionAdapters
end # ActiveRecord

