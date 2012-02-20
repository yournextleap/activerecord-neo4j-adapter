module ActiveRecord
  module HybridDatabaseConnector
    class Migration < ActiveRecord::Migration
      cattr_accessor :database_connection

      def self.connection_for klass
        self.database_connection = klass.connection
      end # connection_for

      def self.connection
        self.database_connection || super
      end # connection

      def method_missing(method, *args, &block)
        logger.info "Invoking: #{method.to_s}"
        super if not method == :connection_for
      end # method_missing
    end # Migration
  end # HybridDatabaseConnector
end # ActiveRecord

ActiveRecord::Migration.send :include, ActiveRecord::HybridDatabaseConnector