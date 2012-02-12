require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  class Base
    def self.sample_db_connection(config)
      ConnectionAdapters::SampleConnectionAdapter.new nil, logger, config
    end
  end

  module ConnectionAdapters
    class SampleConnectionAdapter < AbstractAdapter
      def initialize(connection, log, options)
        super connection, log
      end
    end
  end
end
