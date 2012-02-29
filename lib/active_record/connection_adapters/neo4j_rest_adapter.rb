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

      NATIVE_DATABASE_TYPES = {
                       :primary_key => "integer"
                      }
      def native_database_types
        NATIVE_DATABASE_TYPES
      end

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

      # Quotes the column value to help prevent
      # {SQL injection attacks}[http://en.wikipedia.org/wiki/SQL_injection].
      def quote(value, column = nil)
        # records are quoted as their primary key
        return value.quoted_id if value.respond_to?(:quoted_id)

        case value
          when String, ActiveSupport::Multibyte::Chars
            value = value.to_s
            if column && column.type == :binary && column.class.respond_to?(:string_to_binary)
              "\"#{quote_string(column.class.string_to_binary(value))}\"" # ' (for ruby-mode)
            elsif column && [:integer, :float].include?(column.type)
              value = column.type == :integer ? value.to_i.to_s : "'#{value.to_f.to_s}'"
              value
            else
              "\"#{quote_string(value)}\"" # ' (for ruby-mode)
            end
          when NilClass                 then "null"
          when TrueClass                then (column && column.type == :integer ? '1' : quoted_true)
          when FalseClass               then (column && column.type == :integer ? '0' : quoted_false)
          when Float                    then "'#{value.to_s}'"
          when Fixnum, Bignum           then value.to_s
          # BigDecimals need to be output in a non-normalized form and quoted.
          when BigDecimal               then "'#{value.to_s('F')}'"
          when Symbol                   then "'#{quote_string(value.to_s)}'"
          else
            if value.acts_like?(:date) || value.acts_like?(:time)
              "'#{quoted_date(value)}'"
            else
              "'#{quote_string(value.to_yaml)}'"
            end
        end
      end

      # Quotes a string, escaping any ' (single quote) and \ (backslash)
      # characters.
      def quote_string(s)
        s.gsub(/\\/, '\&\&').gsub(/"/, "\\\"") # ' (for ruby-mode)
      end

    end # ActiveRecord::ConnectionAdapters::Neo4jRestAdapter
  end # ActiveRecord::ConnectionAdapters
end # ActiveRecord
