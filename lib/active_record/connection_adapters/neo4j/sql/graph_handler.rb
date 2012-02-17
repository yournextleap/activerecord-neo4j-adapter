module ActiveRecord
  module ConnectionAdapters
    module Neo4j
      module Sql
        module GraphHandler
          require 'active_record/connection_adapters/neo4j/accessor'
          require 'neography/node'

          include ActiveRecord::ConnectionAdapters::Neo4j::Accessor

          def execute_select(selections)
            #model_node = get_model_node(selections.last[:model])
            #model_node.outgoing('instances').collect{|instance| selections.last[:attributes].collect{|attribute| instance.send(attribute)}}
            #selections.map do |selection|
              neo_server.execute_script(selections.last[:query], {:start_node => get_model_node_id(selections.last[:model])})['data']
            #end
          end

          def execute_insert(insertions)
            model_node = get_model_node(insertions[:model])
            instance_node = Neography::Node.create insertions[:values]
            
            model_node.outgoing('instances') << instance_node
             
          end

          def execute_delete(deletions)
            model_node = get_model_node(deletions.last[:model])
          end

        end # GraphHandler
      end # Sql
    end # Neo4j
  end # ConnectionAdapters
end #ActiveRecord