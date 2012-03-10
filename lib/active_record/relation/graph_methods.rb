module ActiveRecord
  module GraphMethods
    extend ActiveSupport::Concern
    
    def gremlin(query)
      raise NotImplementedError.new("Graph methods aren't implemented for #{klass.to_s}")\
            unless (klass.supports_graph_methods?)

      sources = to_a
      return [] if sources.empty?
      source_ids = sources.map{|source| ((source.respond_to? :node_present? and source.node_present?) ? source.node_id : (source.class.supports_graph_methods? ? source.id : nil))}.compact.join(',')
      query = "g.v(#{source_ids})_().#{query}"

      result_nodes = klass.connection.execute_gremlin query, "Gremlin Methods"

      klass.load_from_graph result_nodes

    end
  end # GraphMethods
end # ActiveRecord

ActiveRecord::Relation.send :include, ActiveRecord::GraphMethods