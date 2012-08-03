module ActiveRecord
  module ConnectionAdapters
    module Neo4j
      module Sql
        module GraphHandler
          require 'active_record/connection_adapters/neo4j/accessor'
          require 'neography/node'

          include ActiveRecord::ConnectionAdapters::Neo4j::Accessor

          def execute_select(selections, name=nil)
            #model_node = get_model_node(selections.last[:model])
            #model_node.outgoing('instances').collect{|instance| selections.last[:attributes].collect{|attribute| instance.send(attribute)}}
            #selections.map do |selection|
              execute_gremlin(selections.last[:query], name, {:start_node => get_model_node_id(selections.last[:model])})
            #end
          end

          def execute_insert(insertions, name=nil)
            model_node = get_model_node(insertions[:model])
            node_id = execute_gremlin(insertions[:query],name)['self'].split('/').last.to_i
            execute_gremlin("model=g.v(#{model_node.neo_id}); instance=g.v(#{node_id}); g.addEdge(model, instance, 'instances')", name)

            execute_gremlin "g.v(#{node_id}).__type__='#{model_node.class_name}'"
            node_id
          end

          def execute_delete(deletion, name=nil)
            execute_gremlin deletion[:query], name, {:start_node => get_model_node_id(deletion[:model])}
          end

          def execute_update(update, name=nil)
            execute_gremlin update[:query], name, {:start_node => get_model_node_id(update[:model])}
          end

          def execute_remove_properties(model_name, *column_names)
            query = [
                      "g",
                      "v(start_node)",
                      "out('instances')",
                      ("each{ #{column_names.map{|column_name| "it.removeProperty('"+column_name.to_s+"')"}.join(';')} }" if column_names.present?),
                    ].compact.join('.')

            execute_gremlin query, nil, {:start_node => get_model_node_id(model_name)}
          end

          def execute_gremlin query, name=nil, params={}
            if name == :skip_logging
              neo_server.execute_script(query, params)
            else
              log(query.blank? ? 'Empty query' : query, name || 'Gremlin') { neo_server.execute_script(query, params) }
            end
          end

        end # GraphHandler
      end # Sql
    end # Neo4j
  end # ConnectionAdapters
end #ActiveRecord
