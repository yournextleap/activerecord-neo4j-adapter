require 'yaml'
require 'active_record/connection_adapters/neo4j_rest_adapter'
class Neo4jRestIllustrator
  # Invoke establish connection from your respective environments
  # Example:
  # <Rails.root>/config/environments/development.rb
  # Neo4jRestIllustrator.connection_name = "graph_development"
  #
  # Alternately, one could also place this in config/application.rb as
  # Neo4jRestIllustrator.connection_name = "graph_#{Rails.env}"

  cattr_accessor :connection_name
  cattr_accessor :connection

  def self.connection
    config = YAML.load_file "#{Rails.root}/config/database.yml"
    config = config[self.connection_name]
    config.symbolize_keys!
    Neography::Config.server = config[:host] if config[:host]
    Neography::Config.port = config[:port] if config[:port]

    @@connection ||= ActiveRecord::ConnectionAdapters::Neo4jRestAdapter.new(Neography::Rest.new, Rails.logger, config)
  end
end
