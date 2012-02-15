module Arel
  module Visitors
    module Neo4j
      class Response
        attr_reader :type, :params
        def initialize(type, options)
          @type = type
          @params = options[:params] if options[:params].present?
        end
      end # Response
    end # Neo4j
  end # Visitors
end # Arel