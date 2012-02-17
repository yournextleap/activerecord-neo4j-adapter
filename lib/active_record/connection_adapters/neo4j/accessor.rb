module ActiveRecord
  module ConnectionAdapters
    module Neo4j
      module Accessor
        def get_model_node(model_name)
          model_node_attributes = neo_server.find_node_index indices[:model], 'model', model_name
          raise ArgumentError.new("Model #{model_name} does not exist!") if not model_node_attributes.present?
          model_node_id = model_node_attributes.first['self'].split('/').last.to_i
          model_node = Neography::Node.load(model_node_id)
        end

        def get_model_node_id(model_name)
          model_node_attributes = neo_server.find_node_index indices[:model], 'model', model_name
          raise ArgumentError.new("Model #{model_name} does not exist!") if not model_node_attributes.present?
          model_node_id = model_node_attributes.first['self'].split('/').last.to_i
        end
      end # Accessor
    end # Neo4j
  end # ConnectionAdapters
end # ActiveRecord