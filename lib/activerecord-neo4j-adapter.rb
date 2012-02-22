require "activerecord-neo4j-adapter/version"
require 'active_record/hybrid_database_connector'
require 'active_record/connection_adapters/neo4j/graph_methods'

module Activerecord
  module Neo4j
    module Adapter
      # Register Neo4j AREL visitor
      require 'arel/visitors/neo4j/sql/neo4j_visitor'
      visitors = Arel::Visitors.send :remove_const, :VISITORS
      visitors['neo4j_rest'] = Arel::Visitors::Neo4j::Sql::Neo4jVisitor
      Arel::Visitors.const_set :VISITORS, visitors
    end
  end
end
