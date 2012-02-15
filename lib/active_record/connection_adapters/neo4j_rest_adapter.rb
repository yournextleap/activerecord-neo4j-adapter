require 'neography/config'
require 'active_record/connection_adapters/neo4j/sql/database_statements'
require 'active_record/connection_adapters/neo4j/sql/graph_handler'

module ActiveRecord
  class Base
    def self.neo4j_rest_connection(config)
      Neography::Config.server = config[:host] if config[:host]
      Neography::Config.port = config[:port] if config[:port]

      ConnectionAdapters::Neo4jRestAdapter.new(Neography::Rest.new, logger)
    end
  end # ActiveRecord::Base

  module ConnectionAdapters
    class Neo4jRestAdapter < AbstractAdapter
      include ActiveRecord::ConnectionAdapters::Neo4j::Sql::DatabaseStatements
      include ActiveRecord::ConnectionAdapters::Neo4j::Sql::GraphHandler

      INDICES = {
                  :model => 'model_index'
                }

      attr_accessor :neo_server

      def initialize(neo4j_server, log)
        self.neo_server = neo4j_server
        super(self.neo_server, log)
        
        # Create model index if it doesn't exist
        neo_server.create_node_index(INDICES[:model]) if not (!!(node_indices = neo_server.list_node_indexes) and !!node_indices[INDICES[:model]])
      end

      def supports_migrations?
        true
      end

      def indices
        INDICES
      end

    end # ActiveRecord::ConnectionAdapters::Neo4jRestAdapter
  end # ActiveRecord::ConnectionAdapters
end # ActiveRecord
